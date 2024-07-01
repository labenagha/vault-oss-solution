locals {
  create = var.create

  launch_template_name    = coalesce(var.launch_template_name, var.name)
  launch_template_id      = var.create_launch_template ? aws_launch_template.this[0].id : var.launch_template_id
  launch_template_version = var.create_launch_template && var.launch_template_version == null ? aws_launch_template.this[0].latest_version : var.launch_template_version
}
