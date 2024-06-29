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
    tls_cert_file              = var.tls_cert_file
    tls_key_file               = var.tls_key_file
    enable_auto_unseal         = var.enable_auto_unseal
    auto_unseal_kms_key_id     = var.auto_unseal_kms_key_id
    auto_unseal_kms_key_region = var.auto_unseal_kms_key_region
    config_dir                 = var.config_dir
    bin_dir                    = var.bin_dir
    user                       = var.user
    enable_s3_backend          = var.enable_s3_backend
    s3_bucket                  = var.s3_bucket
    s3_bucket_path             = var.s3_bucket_path
    s3_bucket_region           = var.s3_bucket_region
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

