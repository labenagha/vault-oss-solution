#!/bin/bash
exec > >(sudo tee -a /var/log/consul_install.log) 2>&1
set -x

USER="consul"
BIN_DIR="/usr/local/bin/$USER"
USER_SYSTEMD_CONFIG_PATH="/etc/systemd/system/$USER.service"
CONSUL_VERSION="1.19.0"
CONSUL_ZIP="consul_1.19.0_linux_amd64.zip"
CONSUL_URL="https://releases.hashicorp.com/consul/$CONSUL_VERSION/$CONSUL_ZIP"

sudo apt-get update
sudo apt-get install -y unzip curl

instance_ip_address=$(curl --silent --location "$ec2_instance_metadata_url/local-ipv4")

export AWS_ACCESS_KEY_ID="${aws_access_key_id}"
export AWS_SECRET_ACCESS_KEY="${aws_secret_access_key}"
export AWS_DEFAULT_REGION="${aws_default_region}"

echo "node_name=${node_name}"
echo "datacenter=${datacenter}"
echo "bootstrap_expect=${bootstrap_expect}"
echo "ec2_instance_metadata_url=${ec2_instance_metadata_url}"

# Create directory for Consul
sudo mkdir -p /usr/local/bin/consul

# Download and unzip Consul
curl -O "$CONSUL_URL"
sudo unzip "$CONSUL_ZIP"
rm "$CONSUL_ZIP"

# Move and link Consul binary
sudo mv consul /usr/local/bin/consul
sudo cp /usr/local/bin/consul/consul /usr/bin/consul

# Create necessary directories and files
sudo mkdir -p /var/consul/data
sudo mkdir -p /usr/local/etc/consul
sudo touch /usr/local/etc/consul/consul_s1.json

# Create Consul configuration file
sudo tee /usr/local/etc/consul/consul_s1.json > /dev/null << EOF
{
  "server": true,
  "node_name": "$node_name",
  "datacenter": "$datacenter",
  "data_dir": "/var/consul/data",
  "bind_addr": "0.0.0.0",
  "client_addr": "0.0.0.0",
  "advertise_addr": "$instance_ip_address",
  "bootstrap_expect": $bootstrap_expect,
  "retry_join": ["$instance_ip_address"],
  "ui": true,
  "log_level": "DEBUG",
  "enable_syslog": true,
  "acl_enforce_version_8": false
}
EOF

# Create PID file directory and file
sudo mkdir -p /var/run/consul
sudo touch /var/run/consul/consul-server.pid

# Create systemd service file for Consul
sudo tee "$USER_SYSTEMD_CONFIG_PATH" > /dev/null << EOF
### BEGIN INIT INFO
# Provides:          consul
# Required-Start:    \$local_fs \$remote_fs
# Required-Stop:     \$local_fs \$remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Consul agent
# Description:       Consul service discovery framework
### END INIT INFO

[Unit]
Description=Consul server agent
Requires=network-online.target
After=network-online.target

[Service]
PIDFile=/var/run/consul/consul-server.pid
PermissionsStartOnly=true
ExecStart=/usr/local/bin/consul/consul agent \
    -config-file=/usr/local/etc/consul/consul_s1.json \
    -pid-file=/var/run/consul/consul-server.pid
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, start and check the status of Consul service
sudo systemctl daemon-reload
sudo systemctl restart consul
sudo systemctl status consul
