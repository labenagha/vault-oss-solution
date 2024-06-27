resource "aws_key_pair" "service_key" {
  key_name   = "service-key"
  public_key = var.public_key
}

resource "aws_instance" "gh_runner_install" {
  ami                         = data.aws_ami.ubuntu_ami.id
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.public_subnet_id[0]
  associate_public_ip_address = true
  security_groups             = [module.vpc.security_group_id]
  key_name                    = aws_key_pair.service_key.key_name
  user_data_base64            = base64encode(data.template_file.gh_runner_install.rendered)

  root_block_device {
    volume_size = 8
  }

  tags = {
    Name = "gh-runner-01"
  }
}