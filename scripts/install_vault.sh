# #!/bin/bash
# # This script is used to configure and run Vault on an AWS server or in a CI environment.

# set -e
# set -x

# VAULT_CONFIG_FILE="default.hcl"
# SYSTEMD_CONFIG_PATH="/etc/systemd/system/vault.service"
# DEFAULT_PORT=8200
# DEFAULT_LOG_LEVEL="info"

# # Download and install Vault
# curl -Lo vault.zip https://releases.hashicorp.com/vault/1.8.0/vault_1.8.0_linux_amd64.zip
# sudo rm -rf vault  # Remove any existing directory named vault
# unzip vault.zip
# sudo mv vault /usr/local/bin/
# vault -v

# # Check if running in GitHub Actions
# if [ "$GITHUB_ACTIONS" = "true" ]; then
#   INSTANCE_IP_ADDRESS="127.0.0.1"
# else
#   EC2_INSTANCE_METADATA_URL="http://169.254.169.254/latest/meta-data"
#   INSTANCE_IP_ADDRESS=$(curl --silent --location "$EC2_INSTANCE_METADATA_URL/local-ipv4" || echo "127.0.0.1")
# fi

# if [[ $1 == "--help" ]]; then
#   echo "Usage: $0 [OPTIONS]"
#   echo "Options:"
#   echo "  --tls-cert-file <file>    Path to the TLS certificate file. Required."
#   echo "  --tls-key-file <file>     Path to the TLS key file. Required."
#   echo "  --port <port>             Port for Vault to listen on. Default: $DEFAULT_PORT"
#   echo "  --config-dir <dir>        Path to the Vault config directory. Default: ./config"
#   echo "  --bin-dir <dir>           Path to the Vault binary directory. Default: ./bin"
#   echo "  --log-level <level>       Log level for Vault. Default: $DEFAULT_LOG_LEVEL"
#   echo "  --user <user>             User to run Vault as. Default: current user"
#   echo "  --enable-s3-backend       Enable S3 backend. Requires --s3-bucket and --s3-bucket-region"
#   echo "  --s3-bucket <bucket>      S3 bucket for storing Vault data"
#   echo "  --s3-bucket-region <region> Region of the S3 bucket"
#   exit 0
# fi

# # Default values
# port=$DEFAULT_PORT
# log_level=$DEFAULT_LOG_LEVEL
# config_dir="./config"
# bin_dir="./bin"
# user=$(whoami)
# enable_s3_backend=false
# s3_bucket=""
# s3_bucket_region=""

# # Parse arguments
# while [[ $# -gt 0 ]]; do
#   case $1 in
#     --tls-cert-file) tls_cert_file="$2"; shift 2;;
#     --tls-key-file) tls_key_file="$2"; shift 2;;
#     --port) port="$2"; shift 2;;
#     --config-dir) config_dir="$2"; shift 2;;
#     --bin-dir) bin_dir="$2"; shift 2;;
#     --log-level) log_level="$2"; shift 2;;
#     --user) user="$2"; shift 2;;
#     --enable-s3-backend) enable_s3_backend=true; shift;;
#     --s3-bucket) s3_bucket="$2"; shift 2;;
#     --s3-bucket-region) s3_bucket_region="$2"; shift 2;;
#     *) echo "Unrecognized argument: $1"; exit 1;;
#   esac
# done

# # Check required arguments
# if [[ -z "$tls_cert_file" || -z "$tls_key_file" ]]; then
#   echo "Error: --tls-cert-file and --tls-key-file are required."
#   exit 1
# fi

# # Ensure required commands are installed
# for cmd in systemctl aws curl jq; do
#   if ! command -v $cmd &> /dev/null; then
#     echo "Error: $cmd is required but not installed."
#     exit 1
#   fi
# done

# # Ensure directories exist
# mkdir -p "$config_dir"
# mkdir -p "$bin_dir"

# # Generate Vault config
# cluster_port=$((port + 1))
# api_addr="https://$INSTANCE_IP_ADDRESS:$port"

# cat > "$config_dir/$VAULT_CONFIG_FILE" <<EOF
# listener "tcp" {
#   address = "0.0.0.0:$port"
#   cluster_address = "0.0.0.0:$cluster_port"
#   tls_cert_file = "$tls_cert_file"
#   tls_key_file = "$tls_key_file"
# }
# EOF

# if $enable_s3_backend; then
#   cat >> "$config_dir/$VAULT_CONFIG_FILE" <<EOF
# storage "s3" {
#   bucket = "$s3_bucket"
#   region = "$s3_bucket_region"
# }
# EOF
# else
#   cat >> "$config_dir/$VAULT_CONFIG_FILE" <<EOF
# storage "file" {
#   path = "/mnt/vault/data"
# }
# EOF
# fi

# cat >> "$config_dir/$VAULT_CONFIG_FILE" <<EOF
# ui = true
# api_addr = "$api_addr"
# EOF

# # Generate systemd config and log it
# sudo bash -c "cat > $SYSTEMD_CONFIG_PATH" <<EOF
# [Unit]
# Description="HashiCorp Vault - A tool for managing secrets"
# Documentation=https://www.vaultproject.io/docs/
# Requires=network-online.target
# After=network-online.target

# [Service]
# User=$user
# Group=$user
# ProtectSystem=full
# ProtectHome=read-only
# PrivateTmp=yes
# PrivateDevices=yes
# SecureBits=keep-caps
# NoNewPrivileges=yes
# ExecStart=$(realpath $bin_dir/vault) server -config $(realpath $config_dir/$VAULT_CONFIG_FILE) -log-level=$log_level
# ExecReload=/bin/kill --signal HUP \$MAINPID
# KillMode=process
# KillSignal=SIGINT
# Restart=on-failure
# RestartSec=5
# TimeoutStopSec=30
# StartLimitIntervalSec=60
# StartLimitBurst=3
# LimitNOFILE=65536

# [Install]
# WantedBy=multi-user.target
# EOF

# # Log the systemd unit file
# echo "Generated systemd unit file:"
# sudo cat $SYSTEMD_CONFIG_PATH

# # Reload systemd and start Vault
# sudo systemctl daemon-reload
# sudo systemctl enable vault.service
# sudo systemctl restart vault.service || { sudo systemctl status vault.service; exit 1; }
# sudo systemctl status vault.service

# export VAULT_ADDR="http://127.0.0.1:8200"
# vault status -tls-skip-verify



set -e
set -x

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

# Ensure required commands are installed
apt-get update
# apt-get install -y curl jq awscli unzip

# Download and install Vault
curl -Lo vault.zip https://releases.hashicorp.com/vault/1.8.0/vault_1.8.0_linux_amd64.zip
rm -rf vault  # Remove any existing directory named vault
unzip vault.zip
mv vault /usr/local/bin/
vault -v

# Generate self-signed certificate (if not provided)
mkdir -p /etc/vault/tls
echo "$TLS_CERT" > /etc/vault/tls/vault.crt
echo "$TLS_KEY" > /etc/vault/tls/vault.key

# Generate Vault config
mkdir -p /etc/vault/config
cat > "/etc/vault/config/$VAULT_CONFIG_FILE" <<EOF
listener "tcp" {
  address = "0.0.0.0:${port}"
  cluster_address = "0.0.0.0:$((port + 1))"
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
api_addr = "https://$INSTANCE_IP_ADDRESS:${port}"
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

export VAULT_ADDR="http://127.0.0.1:8200"
vault status -tls-skip-verify