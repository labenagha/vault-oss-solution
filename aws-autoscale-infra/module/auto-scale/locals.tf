locals {
  create = var.create

  launch_template_name    = coalesce(var.launch_template_name, var.name)
  launch_template_id      = var.create_launch_template ? aws_launch_template.this[0].id : var.launch_template_id
  launch_template_version = var.create_launch_template && var.launch_template_version == null ? aws_launch_template.this[0].latest_version : var.launch_template_version
  # iam_instance_profile_arn           = var.create_iam_instance_profile ? aws_iam_instance_profile.this[0].arn : var.iam_instance_profile_arn
  # iam_instance_profile_name          = !var.create_iam_instance_profile && var.iam_instance_profile_arn == null ? var.iam_instance_profile_name : null
  # internal_iam_instance_profile_name = try(coalesce(var.iam_instance_profile_name, var.iam_role_name), "")
}
