########################################
#### state bucket variables ############
########################################

state_bucket_policy_name = "TerraformStateManagementPolicy"
state_bucket_name        = "ha-vault-dev"


#######################################
##### Consul AutoScaling Configurations ######
#######################################

create                      = true
name                        = "consul-dev-cluster"
launch_template_name        = "launch-template-consul-cluster"
launch_template_id          = null
create_iam_instance_profile = false

# You can set this to a specific version, `$Latest`, or `$Default`
launch_template_version = "$Latest"
# iam_instance_profile_name            = "ha-dev-iam-instance-asg"
# iam_role_name                        = "ha-dev-iam-role"
create_launch_template               = true
launch_template_use_name_prefix      = true
launch_template_description          = "hadev consul launch template description"
ebs_optimized                        = true
image_id                             = "ami-04b70fa74e45c3917"
key_name                             = "service-key"
network_interfaces                   = []
security_groups                      = ["sg-0904c5d1fde7777ff", "sg-0ced9f962e6a7dced"]
instance_initiated_shutdown_behavior = "stop"
block_device_mappings                = []
instance_type                        = "t3.medium"
metadata_options = {
  http_endpoint               = "enabled",
  http_tokens                 = "optional",
  http_put_response_hop_limit = 1,
  http_protocol_ipv6          = "disabled",
  instance_metadata_tags      = "disabled"
}
enable_monitoring = true
tags = {
  Environment = "Dev",
  Project     = "consul-OSS"
}


#######################################
##### Consul AutoScaling group ###############
#######################################
ignore_desired_capacity_changes = false
use_name_prefix                 = false
use_mixed_instances_policy      = false
vpc_zone_identifier             = ["subnet-0078ef2b40c2b7239", "subnet-009590ea08c8b49e4"]
min_size                        = 1
max_size                        = 3
desired_capacity                = 2
desired_capacity_type           = "units"
min_elb_capacity                = 1
wait_for_elb_capacity           = 2
wait_for_capacity_timeout       = "5m"
default_cooldown                = 300
protect_from_scale_in           = false
target_group_arns               = ["arn:aws:elasticloadbalancing:us-east-1:200602878693:targetgroup/consul-load-balancer-tg/83e86bf0a92a7d71"]
placement_group                 = null
health_check_type               = "EC2"
health_check_grace_period       = 120
force_delete                    = false
termination_policies            = ["Default"]

instance_maintenance_policy = {
  min_healthy_percentage = 50
  max_healthy_percentage = 100
}

# Scaling policy specific variables
delete_timeout        = "15m"
create_scaling_policy = true

# scaling_policies = {
#   policy1 = {
#     name                      = "scale-up-policy"
#     adjustment_type           = "ChangeInCapacity"
#     policy_type               = "StepScaling"
#     min_adjustment_magnitude  = 1
#     metric_aggregation_type   = "Average"

#     step_adjustment = [
#       {
#         scaling_adjustment          = 1
#         metric_interval_lower_bound = 1.0
#         metric_interval_upper_bound = 2.0
#       }
#     ]
#   }
# }

#############################################
########## Consul userdata variables ########
#############################################
aws_access_key_id         = "AKIAS5NG5ALSSPZOE4X5"
aws_default_region        = "us-east-1"
ec2_instance_metadata_url = "http://169.254.169.254/latest/meta-data"
node_name                 = "consul-node-1"
datacenter                = "dc1"
bootstrap_expect          = 2
