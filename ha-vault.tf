module "vault" {
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
  user_data                            = var.user_data
  network_interfaces                   = var.network_interfaces
  security_groups                      = var.security_groups
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  block_device_mappings                = var.block_device_mappings
  instance_type                        = var.instance_type
  metadata_options                     = var.metadata_options
  enable_monitoring                    = var.enable_monitoring
  tags                                 = var.tags
}
