#!/bin/bash

exec > >(sudo tee -a /var/log/vault_install.log) 2>&1

set -e
set -x

VAULT_CONFIG_FILE="default.hcl"
SYSTEMD_CONFIG_PATH="/etc/systemd/system/vault.service"
DEFAULT_PORT="${default_port}"
DEFAULT_LOG_LEVEL="info"
iam_user_name="VaultAdminUser"
EC2_INSTANCE_METADATA_URL="http://169.254.169.254/latest/meta-data"

echo "default_port=${default_port}"
echo "TLS_CERT=${TLS_CERT}"
echo "TLS_KEY_FILE=${TLS_KEY_FILE}"
echo "ENABLE_AUTO_UNSEAL=${ENABLE_AUTO_UNSEAL}"
echo "AUTO_UNSEAL_KMS_KEY_ID=${AUTO_UNSEAL_KMS_KEY_ID}"
echo "AUTO_UNSEAL_KMS_KEY_REGION=${AUTO_UNSEAL_KMS_KEY_REGION}"
echo "CONFIG_DIR=${CONFIG_DIR}"
echo "BIN_DIR=${BIN_DIR}"
echo "USER=${USER}"
echo "ENABLE_S3_BACKEND=${ENABLE_S3_BACKEND}"
echo "S3_BUCKET=${S3_BUCKET}"
echo "S3_BUCKET_PATH=${S3_BUCKET_PATH}"
echo "S3_BUCKET_REGION=${S3_BUCKET_REGION}"
echo "account_id=${account_id}"
echo "role_name=${role_name}"
echo "policy_arn=${policy_arn}"
echo "session_name=${session_name}"
echo "initial_aws_access_key_id=${USER_AWS_ACCESS_KEY_ID}"
echo "initial_aws_secret_access_key=${USER_AWS_SECRET_ACCESS_KEY}"
echo "aws_region=${aws_region}"
echo "iam_user_name=${iam_user_name}"


# Install prerequisites
sudo apt-get update
sudo apt-get install -y unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo unzip awscliv2.zip
sudo ./aws/install


export AWS_ACCESS_KEY_ID="${USER_AWS_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${USER_AWS_SECRET_ACCESS_KEY}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION}"


# Create IAM role
cat > trust-policy.json << EOL
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com",
        "AWS": "arn:aws:iam::${account_id}:user/${iam_user_name}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOL

aws iam create-role --role-name "${role_name}" --assume-role-policy-document file://trust-policy.json
aws iam attach-role-policy --role-name "${role_name}" --policy-arn "${policy_arn}"
rm trust-policy.json

# Assume IAM role
aws sts assume-role --role-arn "arn:aws:iam::${account_id}:role/${role_name}" --role-session-name "${session_name}" > assume-role-output.json
export AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' < assume-role-output.json)
export AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' < assume-role-output.json)
export AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' < assume-role-output.json)
rm assume-role-output.json

# Get instance IP address
instance_ip_address=$(curl --silent --location "$EC2_INSTANCE_METADATA_URL/local-ipv4")

# Check if required binaries are installed
for cmd in systemctl curl jq; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "ERROR: The binary '$cmd' is required but not installed."
    exit 1
  fi
done

if [[ -z "${TLS_CERT}" || -z "${TLS_KEY_FILE}" ]]; then
    exit 1
fi

# Create Vault config
mkdir -p "${CONFIG_DIR}"
config_path="${CONFIG_DIR}/$VAULT_CONFIG_FILE"
cat > "$config_path" << EOF
listener "tcp" {
  address = "0.0.0.0:$DEFAULT_PORT"
  tls_cert_file = "${TLS_CERT}"
  tls_key_file = "${TLS_KEY_FILE}"
}
EOF

if [[ "$ENABLE_AUTO_UNSEAL" == "true" ]]; then
  cat >> "$config_path" << EOF
seal "awskms" {
  kms_key_id = "${AUTO_UNSEAL_KMS_KEY_ID}"
  region = "${AUTO_UNSEAL_KMS_KEY_REGION}"
}
EOF
fi

if [[ "$ENABLE_S3_BACKEND" == "true" ]]; then
  cat >> "$config_path" << EOF
storage "s3" {
  bucket = "${S3_BUCKET}"
  path   = "${S3_BUCKET_PATH}"
  region = "${S3_BUCKET_REGION}"
}
EOF
else
  cat >> "$config_path" << EOF
storage "consul" {
  address = "127.0.0.1:8500"
  path = "vault/"
}
EOF
fi

cat >> "$config_path" << EOF
cluster_addr = "https://$instance_ip_address:$((DEFAULT_PORT + 1))"
api_addr = "https://$instance_ip_address:$DEFAULT_PORT"
ui = true
EOF

chown "$USER:$USER" "$config_path"

# Create systemd service config
cat > "$SYSTEMD_CONFIG_PATH" << EOF
[Unit]
Description=HashiCorp Vault - A tool for managing secrets
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target

[Service]
User=$USER
Group=$USER
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=$BIN_DIR/vault server -config=$CONFIG_DIR -log-level=$DEFAULT_LOG_LEVEL
ExecReload=/bin/kill --signal HUP \$MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitIntervalSec=60
StartLimitBurst=3
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd config and start Vault
systemctl daemon-reload
systemctl enable vault.service
systemctl restart vault.service
systemctl status vault.service
