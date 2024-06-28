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

# data "template_file" "user_data" {
#   template = file("${path.module}/scripts/install_vault.sh")
#   vars = {
#     port              = var.port
#     log_level         = var.log_level
#     tls_cert          = var.tls_cert
#     tls_key           = var.tls_key
#     s3_bucket         = var.s3_bucket
#     s3_bucket_region  = var.s3_bucket_region
#     enable_s3_backend = var.enable_s3_backend
#     user              = var.user
#   }
# }

data "template_file" "user_data" {
  template = "scripts/nginx_vault.sh"
  vars = {
    greeting = "Welcome To Nginx UI"
  }
}