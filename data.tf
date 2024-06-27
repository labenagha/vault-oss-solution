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
    GITHUB_ACCESS_TOKEN = var.ACCESS_TOKEN
    RUNNER_URL          = var.RUNNER_URL
    RUNNER_SHA          = var.RUNNER_SHA
    RUNNER_TAR          = var.RUNNER_TAR
  }
}
