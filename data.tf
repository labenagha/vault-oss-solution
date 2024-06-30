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
    TLS_CERT                   = var.TLS_CERT
    TLS_KEY_FILE               = var.TLS_KEY_FILE
    ENABLE_AUTO_UNSEAL         = var.ENABLE_AUTO_UNSEAL
    AUTO_UNSEAL_KMS_KEY_ID     = var.AUTO_UNSEAL_KMS_KEY_ID
    AUTO_UNSEAL_KMS_KEY_REGION = var.AUTO_UNSEAL_KMS_KEY_REGION
    CONFIG_DIR                 = var.CONFIG_DIR
    BIN_DIR                    = var.BIN_DIR
    USER                       = var.USER
    ENABLE_S3_BACKEND          = var.ENABLE_S3_BACKEND
    S3_BUCKET                  = var.S3_BUCKET
    S3_BUCKET_PATH             = var.S3_BUCKET_PATH
    S3_BUCKET_REGION           = var.S3_BUCKET_REGION
    account_id                 = var.account_id
    role_name                  = var.role_name
    policy_arn                 = var.policy_arn
    session_name               = var.session_name
    default_port               = var.default_port
    aws_secret_access_key      = var.aws_secret_access_key
    AWS_ACCESS_KEY_ID          = var.AWS_ACCESS_KEY_ID
    AWS_DEFAULT_REGION         = var.AWS_DEFAULT_REGION
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/scripts/nginx_install.sh")
  vars = {
    greeting = "Welcome To Nginx UI"
  }
}