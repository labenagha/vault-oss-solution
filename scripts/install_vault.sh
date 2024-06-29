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
  sudo mv vault /usr/local/bin/
  vault -v
}
install_vault

# Create vault user if it does not exist
if ! id "vault" &>/dev/null; then
    sudo useradd --system --home /etc/vault --shell /bin/false vault
fi

VAULT_CONFIG_FILE="default.hcl"
SYSTEMD_CONFIG_PATH="/etc/systemd/system/vault.service"
DEFAULT_PORT=8200
DEFAULT_LOG_LEVEL=info

CERT_DIR="/etc/vault/tls"
USER="vault"
INSTANCE_IP_ADDRESS=$(curl --silent --location "http://169.254.169.254/latest/meta-data/local-ipv4")

# Environment variables passed from Terraform
TLS_CERT="${tls_cert}"
TLS_KEY="${tls_key}"
S3_BUCKET="${s3_bucket}"
S3_BUCKET_REGION="${s3_bucket_region}"
ENABLE_S3_BACKEND="${enable_s3_backend}"
AWS_ACCESS_KEY_ID="${aws_access_key_id}"
AWS_SECRET_ACCESS_KEY="${aws_secret_access_key}"

# Ensure the Vault data directory exists
sudo mkdir -p /opt/vault/data

# Create TLS directory and generate self-signed certificate if not provided
sudo mkdir -p $CERT_DIR
if [ ! -f "$CERT_DIR/vault.crt" ] || [ ! -f "$CERT_DIR/vault.key" ]; then
    echo "$TLS_CERT" > $CERT_DIR/vault.crt
    echo "$TLS_KEY" > $CERT_DIR/vault.key
fi

# Generate the certificate if not provided
if [ ! -s "$CERT_DIR/vault.crt" ] || [ ! -s "$CERT_DIR/vault.key" ]; then
  CONFIG_FILE="$CERT_DIR/vault.cnf"
  cat <<EOF | sudo tee $CONFIG_FILE
[ req ]
default_bits       = 2048
distinguished_name = req_distinguished_name
req_extensions     = req_ext
x509_extensions    = v3_req
prompt             = no

[ req_distinguished_name ]
C  = US
ST = State
L  = City
O  = Organization
CN = $INSTANCE_IP_ADDRESS

[ req_ext ]
subjectAltName = @alt_names

[ v3_req ]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = $INSTANCE_IP_ADDRESS
IP.1  = $INSTANCE_IP_ADDRESS
EOF

  sudo openssl req -new -nodes -x509 -days 365 -keyout $CERT_DIR/vault.key -out $CERT_DIR/vault.crt -config $CONFIG_FILE
  sudo chown vault:vault $CERT_DIR/vault.crt $CERT_DIR/vault.key
  sudo chmod 600 $CERT_DIR/vault.crt $CERT_DIR/vault.key
fi

# Set permissions for TLS files
sudo chown -R vault:vault $CERT_DIR
sudo chmod 600 $CERT_DIR/vault.crt
sudo chmod 600 $CERT_DIR/vault.key

# Generate Vault config
sudo mkdir -p /etc/vault/config
sudo cat > "/etc/vault/config/$VAULT_CONFIG_FILE" <<EOF
listener "tcp" {
  address = "0.0.0.0:$DEFAULT_PORT"
  cluster_address = "0.0.0.0:$((DEFAULT_PORT + 1))"
  tls_cert_file = "$CERT_DIR/vault.crt"
  tls_key_file = "$CERT_DIR/vault.key"
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
export VAULT_ADDR="https://$INSTANCE_IP_ADDRESS:$DEFAULT_PORT"
export VAULT_SKIP_VERIFY=true

# sudo VAULT_ADDR="https://$INSTANCE_IP_ADDRESS:$DEFAULT_PORT" VAULT_SKIP_VERIFY=true vault operator init -key-shares=1 -key-threshold=1 | sudo tee /etc/vault/init_output.txt

# # Extract Unseal Key and Root Token
# UNSEAL_KEY=$(grep 'Unseal Key 1:' /etc/vault/init_output.txt | awk '{print $NF}')
# ROOT_TOKEN=$(grep 'Initial Root Token:' /etc/vault/init_output.txt | awk '{print $NF}')

# # Create JSON file for unseal
# echo "{\"key\": \"$UNSEAL_KEY\"}" | sudo tee /tmp/unseal_key.json

# # Unseal Vault using the JSON file
# curl --header "X-Vault-Token: $ROOT_TOKEN" --request PUT --data @/tmp/unseal_key.json https://$INSTANCE_IP_ADDRESS:$DEFAULT_PORT/v1/sys/unseal -k

# # Login to Vault using the Root Token
# VAULT_ADDR="https://$INSTANCE_IP_ADDRESS:$DEFAULT_PORT" VAULT_SKIP_VERIFY=true vault login "$ROOT_TOKEN"
