output "launch_template_id" {
  value = aws_launch_template.this[0].id
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.this[0].name
}
