data "aws_partition" "current" {}

data "aws_iam_policy_document" "assume_role_policy" {
  count = local.create && var.create_iam_instance_profile ? 1 : 0

  statement {
    sid     = "EC2AssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.${data.aws_partition.current.dns_suffix}"]
    }
  }
}

data "template_file" "user_data" {
  count    = var.create_launch_template ? 1 : 0
  template = var.user_data.template
  vars     = var.user_data.vars
}