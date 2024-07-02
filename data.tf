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

data "template_file" "consul_install" {
  template = file("${path.module}/scripts/consul_install.tpl")
  vars = {
    aws_access_key_id         = var.aws_access_key_id
    aws_secret_access_key     = var.aws_secret_access_key
    aws_default_region        = var.aws_default_region
    ec2_instance_metadata_url = var.ec2_instance_metadata_url
    node_name                 = var.node_name
    datacenter                = var.datacenter
    bootstrap_expect          = var.bootstrap_expect
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/scripts/nginx_install.sh")
  vars = {
    greeting = "Welcome To Nginx UI"
  }
}
