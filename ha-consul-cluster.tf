module "consul" {
  source = "./aws-autoscale-infra/module/auto-scale"

  create                               = var.create
  name                                 = var.name
  launch_template_name                 = var.launch_template_name
  launch_template_id                   = var.launch_template_id
  create_iam_instance_profile          = var.create_iam_instance_profile
  launch_template_version              = var.launch_template_version
  iam_instance_profile_arn             = var.iam_instance_profile_arn
  iam_instance_profile_name            = var.iam_instance_profile_name
  iam_role_name                        = var.iam_role_name
  create_launch_template               = var.create_launch_template
  launch_template_use_name_prefix      = var.launch_template_use_name_prefix
  launch_template_description          = var.launch_template_description
  ebs_optimized                        = var.ebs_optimized
  image_id                             = var.image_id
  key_name                             = var.key_name
  user_data                            = base64encode(data.template_file.consul_install.rendered)
  security_groups                      = var.security_groups
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  block_device_mappings                = var.block_device_mappings
  instance_type                        = var.instance_type
  metadata_options                     = var.metadata_options
  enable_monitoring                    = var.enable_monitoring

  # Autoscaling group specific variables
  ignore_desired_capacity_changes = var.ignore_desired_capacity_changes
  use_name_prefix                 = var.use_name_prefix
  use_mixed_instances_policy      = var.use_mixed_instances_policy
  # availability_zones                   = var.availability_zones
  vpc_zone_identifier         = var.vpc_zone_identifier
  min_size                    = var.min_size
  max_size                    = var.max_size
  desired_capacity            = var.desired_capacity
  desired_capacity_type       = var.desired_capacity_type
  min_elb_capacity            = var.min_elb_capacity
  wait_for_elb_capacity       = var.wait_for_elb_capacity
  wait_for_capacity_timeout   = var.wait_for_capacity_timeout
  default_cooldown            = var.default_cooldown
  protect_from_scale_in       = var.protect_from_scale_in
  target_group_arns           = var.target_group_arns
  placement_group             = var.placement_group
  health_check_type           = var.health_check_type
  health_check_grace_period   = var.health_check_grace_period
  force_delete                = var.force_delete
  termination_policies        = var.termination_policies
  instance_maintenance_policy = var.instance_maintenance_policy
  delete_timeout              = var.delete_timeout
  scaling_policies            = var.scaling_policies
  tags                        = var.tags
}