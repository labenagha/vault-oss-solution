#!/bin/bash
# This script is used to configure and run Vault on an AWS server or in a CI environment.

exec > >(sudo tee -a /var/log/vault_install.log) 2>&1
set -e
set -x

sudo apt-get update
sudo apt-get install -y curl jq unzip openssl

install_awscli() {
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  sudo unzip awscliv2.zip
  sudo ./aws/install
}
install_awscli

install_vault() {
  curl -Lo vault.zip https://releases.hashicorp.com/vault/1.17.0/vault_1.17.0_linux_amd64.zip
  sudo unzip vault.zip
  mv vault /usr/local/bin/
  vault -v
}
install_vault

# Create vault user if it does not exist
if ! id "vault" &>/dev/null; then
    sudo useradd --system --home /etc/vault --shell /bin/false vault
fi

VAULT_CONFIG_FILE="default.hcl"
SYSTEMD_CONFIG_PATH="/etc/systemd/system/vault.service"
DEFAULT_PORT=${port}
DEFAULT_LOG_LEVEL=${log_level}

INSTANCE_IP_ADDRESS=$(curl --silent --location "http://169.254.169.254/latest/meta-data/local-ipv4")

# Environment variables passed from Terraform
TLS_CERT="${tls_cert}"
TLS_KEY="${tls_key}"
S3_BUCKET="${s3_bucket}"
S3_BUCKET_REGION="${s3_bucket_region}"
ENABLE_S3_BACKEND="${enable_s3_backend}"
USER="${user}"
AWS_ACCESS_KEY_ID="${aws_access_key_id}"
AWS_SECRET_ACCESS_KEY="${aws_secret_access_key}"

# Create TLS directory and generate self-signed certificate if not provided
sudo mkdir -p /etc/vault/tls
if [ ! -f "/etc/vault/tls/vault.crt" ] || [ ! -f "/etc/vault/tls/vault.key" ]; then
    echo "$TLS_CERT" > /etc/vault/tls/vault.crt
    echo "$TLS_KEY" > /etc/vault/tls/vault.key
fi

# Set permissions for TLS files
sudo chown -R vault:vault /etc/vault/tls
sudo chmod 600 /etc/vault/tls/vault.crt
sudo chmod 600 /etc/vault/tls/vault.key

# Generate Vault config
sudo mkdir -p /etc/vault/config
sudo cat > "/etc/vault/config/$VAULT_CONFIG_FILE" <<EOF
listener "tcp" {
  address = "0.0.0.0:$DEFAULT_PORT"
  cluster_address = "0.0.0.0:$((DEFAULT_PORT + 1))"
  tls_cert_file = "/etc/vault/tls/vault.crt"
  tls_key_file = "/etc/vault/tls/vault.key"
}

storage "s3" {
  bucket = "$S3_BUCKET"
  region = "$S3_BUCKET_REGION"
}

ui = true
api_addr = "https://$INSTANCE_IP_ADDRESS:$DEFAULT_PORT"
disable_mlock = true
EOF

# Set permissions for vault config
sudo chown -R vault:vault /etc/vault/config

# Generate systemd config
sudo cat > "$SYSTEMD_CONFIG_PATH" <<EOF
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
NoNewPrivileges=yes
ExecStart=/usr/local/bin/vault server -config /etc/vault/config/$VAULT_CONFIG_FILE -log-level=$DEFAULT_LOG_LEVEL
ExecReload=/bin/kill --signal HUP \$MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
LimitNOFILE=65536
Environment="AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
Environment="AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
Environment="AWS_REGION=$S3_BUCKET_REGION"

[Install]
WantedBy=multi-user.target
EOF

# Set AWS credentials
sudo mkdir -p /etc/vault/.aws
sudo cat > /etc/vault/.aws/credentials <<EOF
[default]
aws_access_key_id=$AWS_ACCESS_KEY_ID
aws_secret_access_key=$AWS_SECRET_ACCESS_KEY
EOF
sudo chown -R vault:vault /etc/vault/.aws
sudo chmod 600 /etc/vault/.aws/credentials

# Reload systemd and start Vault
sudo systemctl daemon-reload
sudo systemctl enable vault.service
sudo systemctl restart vault.service

# Initialize and unseal Vault
export VAULT_ADDR="https://127.0.0.1:$DEFAULT_PORT"
export VAULT_SKIP_VERIFY=true

vault operator init -key-shares=1 -key-threshold=1 > /etc/vault/init_output.txt
UNSEAL_KEY=$(grep 'Unseal Key 1:' /etc/vault/init_output.txt | awk '{print $NF}')
ROOT_TOKEN=$(grep 'Initial Root Token:' /etc/vault/init_output.txt | awk '{print $NF}')

vault operator unseal "$UNSEAL_KEY"
vault login "$ROOT_TOKEN"
