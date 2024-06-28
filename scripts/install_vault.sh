#!/bin/bash
# This script is used to configure and run Vault on an AWS server or in a CI environment.

exec > >(sudo tee -a /var/log/vault_install.log) 2>&1
set -e
set -x

sudo apt-get update
sudo apt-get install -y curl jq unzip


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

install_awscli() {
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  sudo unzip awscliv2.zip
  sudo ./aws/install
}
install_awscli

install_vault() {
  curl -Lo vault.zip https://releases.hashicorp.com/vault/1.8.0/vault_1.8.0_linux_amd64.zip
  unzip vault.zip
  mv vault /usr/local/bin/
  vault -v
}
install_vault


mkdir -p /etc/vault/tls
echo "$TLS_CERT" > /etc/vault/tls/vault.crt
echo "$TLS_KEY" > /etc/vault/tls/vault.key

# Generate Vault config
mkdir -p /etc/vault/config
cat > "/etc/vault/config/$VAULT_CONFIG_FILE" <<EOF
listener "tcp" {
  address = "0.0.0.0:$DEFAULT_PORT"
  cluster_address = "0.0.0.0:$((DEFAULT_PORT + 1))"
  tls_cert_file = "/etc/vault/tls/vault.crt"
  tls_key_file = "/etc/vault/tls/vault.key"
}
EOF

if [ "$ENABLE_S3_BACKEND" == "true" ]; then
  cat >> "/etc/vault/config/$VAULT_CONFIG_FILE" <<EOF
storage "s3" {
  bucket = "$S3_BUCKET"
  region = "$S3_BUCKET_REGION"
}
EOF
else
  cat >> "/etc/vault/config/$VAULT_CONFIG_FILE" <<EOF
storage "file" {
  path = "/mnt/vault/data"
}
EOF
fi

cat >> "/etc/vault/config/$VAULT_CONFIG_FILE" <<EOF
ui = true
api_addr = "https://$INSTANCE_IP_ADDRESS:$DEFAULT_PORT"
EOF

# Generate systemd config
cat > "$SYSTEMD_CONFIG_PATH" <<EOF
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
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
StartLimitIntervalSec=60
StartLimitBurst=3
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start Vault
systemctl daemon-reload
systemctl enable vault.service
systemctl restart vault.service

export VAULT_ADDR="http://127.0.0.1:$DEFAULT_PORT"
vault status -tls-skip-verify
