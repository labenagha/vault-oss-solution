################################################################################
# Launch template
################################################################################

resource "aws_launch_template" "this" {
  count = var.create_launch_template ? 1 : 0

  name        = var.launch_template_use_name_prefix ? null : local.launch_template_name
  name_prefix = var.launch_template_use_name_prefix ? "${local.launch_template_name}-" : null
  description = var.launch_template_description

  ebs_optimized = var.ebs_optimized
  image_id      = var.image_id
  key_name      = var.key_name
  # user_data     = base64encode(data.template_file.user_data[each.key].rendered)

  vpc_security_group_ids               = length(var.network_interfaces) > 0 ? [] : var.security_groups
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior

  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings
    content {
      device_name  = block_device_mappings.value.device_name
      no_device    = try(block_device_mappings.value.no_device, null)
      virtual_name = try(block_device_mappings.value.virtual_name, null)

      dynamic "ebs" {
        for_each = flatten([try(block_device_mappings.value.ebs, [])])
        content {
          delete_on_termination = try(ebs.value.delete_on_termination, null)
          encrypted             = try(ebs.value.encrypted, null)
          kms_key_id            = try(ebs.value.kms_key_id, null)
          iops                  = try(ebs.value.iops, null)
          throughput            = try(ebs.value.throughput, null)
          snapshot_id           = try(ebs.value.snapshot_id, null)
          volume_size           = try(ebs.value.volume_size, null)
          volume_type           = try(ebs.value.volume_type, null)
        }
      }
    }
  }

  # dynamic "iam_instance_profile" {
  #   for_each = local.iam_instance_profile_name != null || local.iam_instance_profile_arn != null ? [1] : []
  #   content {
  #     name = local.iam_instance_profile_name
  #     arn  = local.iam_instance_profile_arn
  #   }
  # }

  instance_type = var.instance_type


  dynamic "metadata_options" {
    for_each = length(var.metadata_options) > 0 ? [var.metadata_options] : []
    content {
      http_endpoint               = try(metadata_options.value.http_endpoint, null)
      http_tokens                 = try(metadata_options.value.http_tokens, null)
      http_put_response_hop_limit = try(metadata_options.value.http_put_response_hop_limit, null)
      http_protocol_ipv6          = try(metadata_options.value.http_protocol_ipv6, null)
      instance_metadata_tags      = try(metadata_options.value.instance_metadata_tags, null)
    }
  }

  dynamic "monitoring" {
    for_each = var.enable_monitoring ? [1] : []
    content {
      enabled = var.enable_monitoring
    }
  }

  dynamic "network_interfaces" {
    for_each = var.network_interfaces
    content {
      associate_public_ip_address = try(network_interfaces.value.associate_public_ip_address, null)
      delete_on_termination       = try(network_interfaces.value.delete_on_termination, null)
      description                 = try(network_interfaces.value.description, null)
      device_index                = try(network_interfaces.value.device_index, null)
      interface_type              = try(network_interfaces.value.interface_type, null)
      ipv4_prefix_count           = try(network_interfaces.value.ipv4_prefix_count, null)
      ipv4_prefixes               = try(network_interfaces.value.ipv4_prefixes, null)
      ipv4_addresses              = try(network_interfaces.value.ipv4_addresses, [])
      ipv4_address_count          = try(network_interfaces.value.ipv4_address_count, null)
      network_interface_id        = try(network_interfaces.value.network_interface_id, null)
      private_ip_address          = try(network_interfaces.value.private_ip_address, null)
      security_groups             = compact(concat(try(network_interfaces.value.security_groups, []), var.security_groups))
      subnet_id                   = try(network_interfaces.value.subnet_id, null)
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "aws_autoscaling_group" "this" {
  count = local.create && !var.ignore_desired_capacity_changes ? 1 : 0

  name        = var.use_name_prefix ? null : var.name
  name_prefix = var.use_name_prefix ? "${var.name}-" : null

  dynamic "launch_template" {
    for_each = var.use_mixed_instances_policy ? [] : [1]

    content {
      id      = local.launch_template_id
      version = local.launch_template_version
    }
  }

  # availability_zones  = var.availability_zones
  vpc_zone_identifier = var.vpc_zone_identifier

  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  desired_capacity_type     = var.desired_capacity_type
  min_elb_capacity          = var.min_elb_capacity
  wait_for_elb_capacity     = var.wait_for_elb_capacity
  wait_for_capacity_timeout = var.wait_for_capacity_timeout
  default_cooldown          = var.default_cooldown
  protect_from_scale_in     = var.protect_from_scale_in
  # load_balancers            = var.load_balancers
  target_group_arns         = var.target_group_arns
  placement_group           = var.placement_group
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  force_delete              = var.force_delete
  termination_policies      = var.termination_policies

  dynamic "instance_maintenance_policy" {
    for_each = length(var.instance_maintenance_policy) > 0 ? [var.instance_maintenance_policy] : []
    content {
      min_healthy_percentage = instance_maintenance_policy.value.min_healthy_percentage
      max_healthy_percentage = instance_maintenance_policy.value.max_healthy_percentage
    }
  }

  timeouts {
    delete = var.delete_timeout
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      load_balancers,
      target_group_arns,
    ]
  }
}

# ################################################################################
# # Autoscaling Policy
# ################################################################################

resource "aws_autoscaling_policy" "this" {
  for_each = { for k, v in var.scaling_policies : k => v if local.create && var.create_scaling_policy }

  name                   = try(each.value.name, each.key)
  autoscaling_group_name = aws_autoscaling_group.this[0].name

  adjustment_type           = try(each.value.adjustment_type, null)
  policy_type               = try(each.value.policy_type, null)
  estimated_instance_warmup = try(each.value.estimated_instance_warmup, null)
  cooldown                  = try(each.value.cooldown, null)
  min_adjustment_magnitude  = try(each.value.min_adjustment_magnitude, null)
  metric_aggregation_type   = try(each.value.metric_aggregation_type, null)
  scaling_adjustment        = try(each.value.scaling_adjustment, null)

  dynamic "step_adjustment" {
    for_each = try(each.value.step_adjustment, [])
    content {
      scaling_adjustment          = step_adjustment.value.scaling_adjustment
      metric_interval_lower_bound = try(step_adjustment.value.metric_interval_lower_bound, null)
      metric_interval_upper_bound = try(step_adjustment.value.metric_interval_upper_bound, null)
    }
  }
}

# ################################################################################
# # IAM Role / Instance Profile
# ################################################################################

# resource "aws_iam_role" "this" {
#   count = local.create && var.create_iam_instance_profile ? 1 : 0

#   name        = var.iam_role_use_name_prefix ? null : local.internal_iam_instance_profile_name
#   name_prefix = var.iam_role_use_name_prefix ? "${local.internal_iam_instance_profile_name}-" : null
#   path        = var.iam_role_path
#   description = var.iam_role_description

#   assume_role_policy    = data.aws_iam_policy_document.assume_role_policy[0].json
#   permissions_boundary  = var.iam_role_permissions_boundary
#   force_detach_policies = true

#   tags = merge(var.tags, var.iam_role_tags)
# }

# resource "aws_iam_role_policy_attachment" "this" {
#   for_each = { for k, v in var.iam_role_policies : k => v if var.create && var.create_iam_instance_profile }

#   policy_arn = each.value
#   role       = aws_iam_role.this[0].name
# }

# resource "aws_iam_instance_profile" "this" {
#   count = local.create && var.create_iam_instance_profile ? 1 : 0

#   role = aws_iam_role.this[0].name

#   name        = var.iam_role_use_name_prefix ? null : var.iam_role_name
#   name_prefix = var.iam_role_use_name_prefix ? "${var.iam_role_name}-" : null
#   path        = var.iam_role_path

#   tags = merge(var.tags, var.iam_role_tags)
# }