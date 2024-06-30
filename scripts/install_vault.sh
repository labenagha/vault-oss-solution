#!/bin/bash
exec > >(sudo tee -a /var/log/vault_install.log) 2>&1
set -x

VAULT_VERSION="1.17.1"
CONSUL_VERSION="1.11.1"

VAULT_CONFIG_FILE="default.hcl"
SYSTEMD_CONFIG_PATH="/etc/systemd/system/vault.service"
CONSUL_SYSTEMD_CONFIG_PATH="/etc/systemd/system/consul.service"
DEFAULT_PORT="8200"
DEFAULT_LOG_LEVEL="info"
iam_user_name="VaultAdminUser"
EC2_INSTANCE_METADATA_URL="http://169.254.169.254/latest/meta-data"
CONFIG_DIR="/etc/vault"
BIN_DIR="/usr/local/bin"
USER="vault"

# Install prerequisites
sudo apt-get update
sudo apt-get install -y unzip jq curl

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo unzip awscliv2.zip
sudo ./aws/install

# Install Consul
CONSUL_ZIP="consul_$CONSUL_VERSION_linux_amd64.zip"
curl -O https://releases.hashicorp.com/consul/$CONSUL_VERSION/$CONSUL_ZIP
sudo unzip $CONSUL_ZIP
sudo mv consul $BIN_DIR
rm $CONSUL_ZIP

# Install Vault
VAULT_ZIP="vault_$VAULT_VERSION_linux_amd64.zip"
curl -O https://releases.hashicorp.com/vault/$VAULT_VERSION/$VAULT_ZIP
sudo unzip $VAULT_ZIP
sudo mv vault $BIN_DIR
rm $VAULT_ZIP

# Set up Consul
sudo useradd --system --home /etc/consul.d --shell /bin/false consul
sudo mkdir --parents /opt/consul /etc/consul.d
sudo chown --recursive consul:consul /opt/consul /etc/consul.d

# Create Consul config
sudo cat > /etc/consul.d/consul.hcl << EOF
datacenter = "dc1"
data_dir = "/opt/consul"
log_level = "INFO"
node_name = "consul-server"
server = true
ui = true
bind_addr = "0.0.0.0"
client_addr = "0.0.0.0"
bootstrap_expect = 1
EOF

# Create systemd service for Consul
sudo cat > "$CONSUL_SYSTEMD_CONFIG_PATH" << EOF
[Unit]
Description=HashiCorp Consul - A service mesh solution
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target

[Service]
User=consul
Group=consul
ExecStart=$BIN_DIR/consul agent -config-dir=/etc/consul.d/
ExecReload=/bin/kill --signal HUP \$MAINPID
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable consul.service
sudo systemctl start consul.service

export AWS_ACCESS_KEY_ID="${USER_AWS_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${USER_AWS_SECRET_ACCESS_KEY}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION}"

# Create IAM role
sudo cat > trust-policy.json << EOL
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com",
        "AWS": "arn:aws:iam::${account_id}:user/$iam_user_name"
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

# Create OpenSSL config for generating the certificate
sudo cat > /etc/vault/openssl.cnf << EOF
[ req ]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[ req_distinguished_name ]
C = US
ST = Texas
L = Dallas
O = TSRLearning LLC
OU = TSR
CN = $instance_ip_address

[ v3_req ]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[ alt_names ]
IP.1 = $instance_ip_address
DNS.1 = www.tsrlearning.link
EOF

# Generate TLS certificate and key
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/vault/vault.key -out /etc/vault/vault.crt -config /etc/vault/openssl.cnf
sudo chown vault:vault /etc/vault/vault.crt /etc/vault/vault.key
sudo chmod 640 /etc/vault/vault.crt /etc/vault/vault.key

# Create Vault config
sudo mkdir -p "${CONFIG_DIR}"
config_path="${CONFIG_DIR}/$VAULT_CONFIG_FILE"
sudo cat > "$config_path" << EOF
listener "tcp" {
  address = "0.0.0.0:$DEFAULT_PORT"
  tls_cert_file = "/etc/vault/vault.crt"
  tls_key_file = "/etc/vault/vault.key"
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
  sudo cat >> "$config_path" << EOF
storage "s3" {
  bucket = "${S3_BUCKET}"
  path   = "${S3_BUCKET_PATH}"
  region = "${S3_BUCKET_REGION}"
}
EOF
else
  sudo cat >> "$config_path" << EOF
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

# Create vault user and group
sudo groupadd --system vault
sudo useradd --system --home /etc/vault --shell /bin/false --gid vault vault
sudo chown vault:vault "$config_path"

# Create systemd service config for Vault
sudo cat > "$SYSTEMD_CONFIG_PATH" << EOF
[Unit]
Description=HashiCorp Vault - A tool for managing secrets
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target

[Service]
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=$BIN_DIR/vault server -config=$CONFIG_DIR/$VAULT_CONFIG_FILE -log-level=$DEFAULT_LOG_LEVEL
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
sudo systemctl daemon-reload
sudo systemctl enable vault.service
sudo systemctl start vault.service
sudo systemctl status vault.service

# Initialize Vault
export VAULT_ADDR="https://127.0.0.1:$DEFAULT_PORT"
export VAULT_CACERT="/etc/vault/vault.crt"

# vault operator init -key-shares=5 -key-threshold=3 > /etc/vault/init-keys.txt

# # Unseal Vault
# for key in $(grep 'Unseal Key' /etc/vault/init-keys.txt | awk '{print $NF}'); do
#   vault operator unseal $key
# done

# # Login with the root token
# vault login $(grep 'Initial Root Token:' /etc/vault/init-keys.txt | awk '{print $NF}')
