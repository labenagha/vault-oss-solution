#!/bin/bash

exec > >(sudo tee -a /var/log/vault_install.log) 2>&1

set -e
set -x

VAULT_CONFIG_FILE="default.hcl"
SYSTEMD_CONFIG_PATH="/etc/systemd/system/vault.service"

DEFAULT_PORT="${default_port}"
DEFAULT_LOG_LEVEL="info"

EC2_INSTANCE_METADATA_URL="http://169.254.169.254/latest/meta-data"

# log() {
#   local level="$1"
#   local message="$2"
#   echo "$(date +"%Y-%m-%d %H:%M:%S") [$level] $message"
# }

function install_preq() {
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  sudo unzip awscliv2.zip
  sudo ./aws/install
}

create_iam_role() {
  local role_name="${role_name}"
  local policy_arn="${policy_arn}"

  log "INFO" "Creating IAM role ${role_name}"
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

  aws iam create-role --role-name "${role_name}" --assume-role-policy-document file://trust-policy.json
  aws iam attach-role-policy --role-name "${role_name}" --policy-arn "${policy_arn}"
  rm trust-policy.json
}

assume_role() {
  local account_id="${account_id}"
  local role_name="${role_name}"
  local session_name=${session_name}

  log "INFO" "Assuming IAM role ${role_name}"
  aws sts assume-role --role-arn "arn:aws:iam::${account_id}:role/${role_name}" --role-session-name "${session_name}" > assume-role-output.json

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
  local tls_cert_file="${TLS_CERT_FILE}"
  local tls_key_file="${TLS_KEY_FILE}"
  local enable_auto_unseal="${ENABLE_AUTO_UNSEAL}"
  local auto_unseal_kms_key_id="${AUTO_UNSEAL_KMS_KEY_ID}"
  local auto_unseal_kms_key_region="${AUTO_UNSEAL_KMS_KEY_REGION}"
  local config_dir="${CONFIG_DIR}"
  local user="${USER}"
  local enable_s3_backend="${ENABLE_S3_BACKEND}"
  local s3_bucket="${S3_BUCKET}"
  local s3_bucket_path="${S3_BUCKET_PATH}"
  local s3_bucket_region="${S3_BUCKET_REGION}"

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
  local systemd_config_path="$SYSTEMD_CONFIG_PATH"
  local vault_config_dir="${CONFIG_DIR}"
  local vault_bin_dir="${BIN_DIR}"
  local log_level="$DEFAULT_LOG_LEVEL"
  local user="${USER}"

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
  if [[ -z "$TLS_CERT_FILE" || -z "$TLS_KEY_FILE" ]]; then
    log "ERROR" "TLS cert and key files are required."
    exit 1
  fi

  check_installed "systemctl"
  # check_installed "aws"
  check_installed "curl"
  check_installed "jq"

  create_iam_role "$ROLE_NAME" "$POLICY_ARN"
  assume_role "$ACCOUNT_ID" "$ROLE_NAME" "$SESSION_NAME"

  mkdir -p "${CONFIG_DIR}"
  create_vault_config
  create_systemd_config
  start_vault
}

main
