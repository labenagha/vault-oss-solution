#!/bin/bash
# This script creates an IAM role, assumes the role to get temporary credentials,
# and configures and runs Vault with Consul for HA and AWS KMS for auto unseal.

set -e

VAULT_CONFIG_FILE="default.hcl"
SYSTEMD_CONFIG_PATH="/etc/systemd/system/vault.service"

DEFAULT_PORT=8200
DEFAULT_LOG_LEVEL="info"

EC2_INSTANCE_METADATA_URL="http://169.254.169.254/latest/meta-data"
ROLE_NAME="VaultAdminRole"
POLICY_ARN="arn:aws:iam::aws:policy/AdministratorAccess"
SESSION_NAME="VaultSession"

log() {
  local level="$1"
  local message="$2"
  echo "$(date +"%Y-%m-%d %H:%M:%S") [$level] $message"
}

create_iam_role() {
  log "INFO" "Creating IAM role ${ROLE_NAME}"
  cat > trust-policy.json << EOL
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOL

  aws iam create-role --role-name "${ROLE_NAME}" --assume-role-policy-document file://trust-policy.json
  aws iam attach-role-policy --role-name "${ROLE_NAME}" --policy-arn "${POLICY_ARN}"
  rm trust-policy.json
}

assume_role() {
  log "INFO" "Assuming IAM role ${ROLE_NAME}"
  aws sts assume-role --role-arn "arn:aws:iam::$ACCOUNT_ID:role/${ROLE_NAME}" --role-session-name "${SESSION_NAME}" > assume-role-output.json

  export AWS_ACCESS_KEY_ID=$(cat assume-role-output.json | jq -r '.Credentials.AccessKeyId')
  export AWS_SECRET_ACCESS_KEY=$(cat assume-role-output.json | jq -r '.Credentials.SecretAccessKey')
  export AWS_SESSION_TOKEN=$(cat assume-role-output.json | jq -r '.Credentials.SessionToken')
  
  rm assume-role-output.json
}

get_instance_ip_address() {
  curl --silent --location "$EC2_INSTANCE_METADATA_URL/local-ipv4"
}

check_installed() {
  local name="$1"
  if ! command -v "$name" &> /dev/null; then
    log "ERROR" "The binary '$name' is required but not installed."
    exit 1
  fi
}

create_vault_config() {
  local tls_cert_file="$1"
  local tls_key_file="$2"
  local enable_auto_unseal="$3"
  local auto_unseal_kms_key_id="$4"
  local auto_unseal_kms_key_region="$5"
  local config_dir="$6"
  local user="$7"
  local enable_s3_backend="$8"
  local s3_bucket="$9"
  local s3_bucket_path="${10}"
  local s3_bucket_region="${11}"

  local instance_ip_address
  instance_ip_address=$(get_instance_ip_address)

  local config_path="$config_dir/$VAULT_CONFIG_FILE"
  log "INFO" "Creating Vault config file at $config_path"

  {
    echo "listener \"tcp\" {"
    echo "  address = \"0.0.0.0:$DEFAULT_PORT\""
    echo "  tls_cert_file = \"$tls_cert_file\""
    echo "  tls_key_file = \"$tls_key_file\""
    echo "}"

    if [[ "$enable_auto_unseal" == "true" ]]; then
      echo "seal \"awskms\" {"
      echo "  kms_key_id = \"$auto_unseal_kms_key_id\""
      echo "  region = \"$auto_unseal_kms_key_region\""
      echo "}"
    fi

    if [[ "$enable_s3_backend" == "true" ]]; then
      echo "storage \"s3\" {"
      echo "  bucket = \"$s3_bucket\""
      echo "  path   = \"$s3_bucket_path\""
      echo "  region = \"$s3_bucket_region\""
      echo "}"
    else
      echo "storage \"consul\" {"
      echo "  address = \"127.0.0.1:8500\""
      echo "  path = \"vault/\""
      echo "}"
    fi

    echo "cluster_addr = \"https://$instance_ip_address:$((DEFAULT_PORT + 1))\""
    echo "api_addr = \"https://$instance_ip_address:$DEFAULT_PORT\""
    echo "ui = true"
  } > "$config_path"

  chown "$user:$user" "$config_path"
}

create_systemd_config() {
  local systemd_config_path="$1"
  local vault_config_dir="$2"
  local vault_bin_dir="$3"
  local log_level="$4"
  local user="$5"

  log "INFO" "Creating systemd config file at $systemd_config_path"

  {
    echo "[Unit]"
    echo "Description=HashiCorp Vault - A tool for managing secrets"
    echo "Documentation=https://www.vaultproject.io/docs/"
    echo "Requires=network-online.target"
    echo "After=network-online.target"

    echo "[Service]"
    echo "User=$user"
    echo "Group=$user"
    echo "ProtectSystem=full"
    echo "ProtectHome=read-only"
    echo "PrivateTmp=yes"
    echo "PrivateDevices=yes"
    echo "SecureBits=keep-caps"
    echo "AmbientCapabilities=CAP_IPC_LOCK"
    echo "Capabilities=CAP_IPC_LOCK+ep"
    echo "CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK"
    echo "NoNewPrivileges=yes"
    echo "ExecStart=$vault_bin_dir/vault server -config=$vault_config_dir -log-level=$log_level"
    echo "ExecReload=/bin/kill --signal HUP \$MAINPID"
    echo "KillMode=process"
    echo "KillSignal=SIGINT"
    echo "Restart=on-failure"
    echo "RestartSec=5"
    echo "TimeoutStopSec=30"
    echo "StartLimitIntervalSec=60"
    echo "StartLimitBurst=3"
    echo "LimitNOFILE=65536"

    echo "[Install]"
    echo "WantedBy=multi-user.target"
  } > "$systemd_config_path"
}

start_vault() {
  log "INFO" "Reloading systemd config and starting Vault"
  systemctl daemon-reload
  systemctl enable vault.service
  systemctl restart vault.service
}

main() {
  local tls_cert_file="$1"
  local tls_key_file="$2"
  local enable_auto_unseal="$3"
  local auto_unseal_kms_key_id="$4"
  local auto_unseal_kms_key_region="$5"
  local config_dir="$6"
  local bin_dir="$7"
  local user="$8"
  local enable_s3_backend="$9"
  local s3_bucket="${10}"
  local s3_bucket_path="${11}"
  local s3_bucket_region="${12}"
  local account_id="${13}"

  if [[ -z "$tls_cert_file" || -z "$tls_key_file" ]]; then
    log "ERROR" "TLS cert and key files are required."
    exit 1
  fi

  check_installed "systemctl"
  check_installed "aws"
  check_installed "curl"
  check_installed "jq"

  ACCOUNT_ID="$account_id"
  create_iam_role
  assume_role

  mkdir -p "$config_dir"
  create_vault_config "$tls_cert_file" "$tls_key_file" "$enable_auto_unseal" "$auto_unseal_kms_key_id" "$auto_unseal_kms_key_region" "$config_dir" "$user" "$enable_s3_backend" "$s3_bucket" "$s3_bucket_path" "$s3_bucket_region"
  create_systemd_config "$SYSTEMD_CONFIG_PATH" "$config_dir" "$bin_dir" "$DEFAULT_LOG_LEVEL" "$user"
  start_vault
}

main "$@"
