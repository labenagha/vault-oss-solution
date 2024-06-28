########################################
#### state bucket variables ############
########################################

state_bucket_policy_name = "TerraformStateManagementPolicy"
state_bucket_name        = "ha-vault-dev"


#######################################
##### AutoScaling Configurations ######
#######################################

create                      = true
name                        = "vault-dev-cluster-01"
launch_template_name        = "launch-template-vault-cluster-01"
launch_template_id          = null
create_iam_instance_profile = false

# You can set this to a specific version, `$Latest`, or `$Default`
launch_template_version = "$Latest"
# iam_instance_profile_name            = "ha-dev-iam-instance-asg"
# iam_role_name                        = "ha-dev-iam-role"
create_launch_template               = true
launch_template_use_name_prefix      = true
launch_template_description          = "ha-dev vault launch template description"
ebs_optimized                        = true
image_id                             = "ami-04b70fa74e45c3917"
key_name                             = "service-key"
network_interfaces                   = []
security_groups                      = ["sg-0904c5d1fde7777ff", "sg-0ced9f962e6a7dced"]
instance_initiated_shutdown_behavior = "stop"
block_device_mappings                = []
instance_type                        = "t3.medium"

metadata_options = {
  http_endpoint               = "enabled",
  http_tokens                 = "optional",
  http_put_response_hop_limit = 1,
  http_protocol_ipv6          = "disabled",
  instance_metadata_tags      = "disabled"
}

enable_monitoring = true
tags = {
  Environment = "Dev",
  Project     = "Vault-OSS"
}


#######################################
##### AutoScaling group ###############
#######################################

ignore_desired_capacity_changes = false
use_name_prefix                 = false
use_mixed_instances_policy      = false
vpc_zone_identifier             = ["subnet-0078ef2b40c2b7239", "subnet-009590ea08c8b49e4"]
min_size                        = 1
max_size                        = 3
desired_capacity                = 2
desired_capacity_type           = "units"
min_elb_capacity                = 1
wait_for_elb_capacity           = 2
wait_for_capacity_timeout       = "5m"
default_cooldown                = 300
protect_from_scale_in           = false
target_group_arns               = ["arn:aws:elasticloadbalancing:us-east-1:200602878693:targetgroup/hadev-vault-load-balancer-tg/0f49e27da6359eb1"]
placement_group                 = null
health_check_type               = "EC2"
health_check_grace_period       = 300
force_delete                    = false
termination_policies            = ["Default"]

instance_maintenance_policy = {
  min_healthy_percentage = 50
  max_healthy_percentage = 100
}

# Scaling policy specific variables
delete_timeout        = "15m"
create_scaling_policy = true

scaling_policies = {
  policy1 = {
    name                      = "scale-up-policy"
    adjustment_type           = "ChangeInCapacity"
    policy_type               = "SimpleScaling"
    estimated_instance_warmup = 300
    cooldown                  = 300
    min_adjustment_magnitude  = 1
    metric_aggregation_type   = "Average"
    step_adjustment = [
      {
        scaling_adjustment          = 2
        metric_interval_lower_bound = 0
        metric_interval_upper_bound = null
      }
    ]
  }
}

user_data = <<-EOF
  #!/bin/bash
  # This script is used to configure and run Vault on an AWS server or in a CI environment.

  exec > >(sudo tee -a /var/log/vault_install.log) 2>&1
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
  apt-get install -y curl jq awscli unzip

  # Download and install Vault
  curl -Lo vault.zip https://releases.hashicorp.com/vault/1.8.0/vault_1.8.0_linux_amd64.zip
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
    address = "0.0.0.0:${DEFAULT_PORT}"
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
  api_addr = "https://$INSTANCE_IP_ADDRESS:${DEFAULT_PORT}"
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

  export VAULT_ADDR="http://127.0.0.1:${DEFAULT_PORT}"
  vault status -tls-skip-verify
EOF


user_data_vars = {
  port              = 8200
  log_level         = "info"
  tls_cert          = "../certs/tls-cert.pem"
  tls_key           = "../certs/tls-key.pem"
  s3_bucket         = "consul-vault-cluster-dev"
  s3_bucket_region  = "us-east-1"
  enable_s3_backend = "true"
  user              = "vault"
}