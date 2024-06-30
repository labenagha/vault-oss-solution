data "aws_caller_identity" "current" {}

data "aws_ami" "ubuntu_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

data "template_file" "gh_runner_install" {
  template = file("${path.module}/scripts/runner_install.sh")

  vars = {
    RUNNER_SHA          = var.RUNNER_SHA
    RUNNER_VERSION      = var.RUNNER_VERSION
    GITHUB_ACCESS_TOKEN = var.ACCESS_TOKEN
  }
}

data "template_file" "vault_install" {
  template = file("${path.module}/scripts/install_vault.sh")
  vars = {
    tls_cert_file              = var.TLS_CERT_FILE
    tls_key_file               = var.TLS_KEY_FILE
    enable_auto_unseal         = var.ENABLE_AUTO_UNSEAL
    auto_unseal_kms_key_id     = var.AUTO_UNSEAL_KMS_KEY_ID
    auto_unseal_kms_key_region = var.AUTO_UNSEAL_KMS_KEY_REGION
    config_dir                 = var.CONFIG_DIR
    bin_dir                    = var.BIN_DIR
    user                       = var.user
    enable_s3_backend          = var.ENABLE_S3_BACKEND
    s3_bucket                  = var.S3_BUCKET
    s3_bucket_path             = var.S3_BUCKET_PATH
    s3_bucket_region           = var.S3_BUCKET_REGION
    account_id                 = var.account_id
    role_name                  = var.role_name
    policy_arn                 = var.policy_arn
    session_name               = var.session_name
    default_port               = var.default_port
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/scripts/nginx_install.sh")
  vars = {
    greeting = "Welcome To Nginx UI"
  }
}

