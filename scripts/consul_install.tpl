#!/bin/bash
exec > >(sudo tee -a /var/log/consul_install.log) 2>&1
set -x

USER="consul"
BIN_DIR="/usr/local/bin/$USER"
USER_SYSTEMD_CONFIG_PATH="/etc/systemd/system/$USER.service"

sudo apt-get update
sudo apt-get install -y unzip curl

export AWS_ACCESS_KEY_ID="${aws_access_key_id}"
export AWS_SECRET_ACCESS_KEY="${aws_secret_access_key}"
export AWS_DEFAULT_REGION="${aws_default_region}"

echo "node_name=${node_name}"
echo "datacenter=${datacenter}"
echo "bootstrap_expect=${bootstrap_expect}"
echo "consul_zip=${consul_zip}"
echo "ec2_instance_metadata_url=${ec2_instance_metadata_url}"

instance_ip_address=$(curl --silent --location "${ec2_instance_metadata_url}/local-ipv4")

CONSUL_ZIP="${consul_zip}"
curl -O "${consul_zip}"
sudo unzip "$CONSUL_ZIP" -d /usr/local/bin/
rm "$CONSUL_ZIP"

sudo mkdir -p "$BIN_DIR"
sudo mv /usr/local/bin/consul "$BIN_DIR"
sudo ln -s "$BIN_DIR/consul" /usr/bin/consul

sudo useradd --system --home /etc/$USER.d --shell /bin/false $USER
sudo mkdir --parents /opt/$USER /etc/$USER.d
sudo chown --recursive $USER:$USER /opt/$USER /etc/$USER.d

sudo mkdir -p /var/$USER/data
sudo mkdir -p /usr/local/etc/$USER

sudo tee /usr/local/etc/$USER/$USER_s1.json > /dev/null << EOF
{
  "server": true,
  "node_name": "$node_name",
  "datacenter": "$datacenter",
  "data_dir": "/var/$USER/data",
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

sudo tee "$USER_SYSTEMD_CONFIG_PATH" > /dev/null << EOF
### BEGIN INIT INFO
# Provides:          $USER
# Required-Start:    \$local_fs \$remote_fs
# Required-Stop:     \$local_fs \$remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: $USER agent
# Description:       $USER service discovery framework
### END INIT INFO

[Unit]
Description=$USER server agent
Requires=network-online.target
After=network-online.target

[Service]
PIDFile=/var/run/$USER/$USER-server.pid
PermissionsStartOnly=true
ExecStart=/usr/local/bin/$USER agent \
    -config-file=/usr/local/etc/$USER/$USER_s1.json \
    -pid-file=/var/run/$USER/$USER-server.pid
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl restart $USER
sudo systemctl status $USER
