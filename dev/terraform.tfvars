########################################
#### state bucket variables ############
########################################

state_bucket_policy_name = "TerraformStateManagementPolicy"
state_bucket_name        = "ha-vault-dev"


#######################################
##### AutoScaling Configurations ######
#######################################

create                      = true
name                        = "ha-dev-vault"
launch_template_name        = "ha-dev-launch-template"
launch_template_id          = null      # Set to the existing launch template ID if any, otherwise leave as null
create_iam_instance_profile = false     # Set to true if you need to create a new IAM instance profile
launch_template_version     = "$Latest" # You can set this to a specific version, `$Latest`, or `$Default`
# iam_instance_profile_arn             = null  # Set the ARN of the existing IAM instance profile if `create_iam_instance_profile` is false
iam_instance_profile_name       = "ha-dev-iam-instance-profile"
iam_role_name                   = "ha-dev-iam-role"
create_launch_template          = true
launch_template_use_name_prefix = true
launch_template_description     = "ha-dev launch template description"
ebs_optimized                   = true
image_id                        = "ami-04b70fa74e45c3917" # Replace with your AMI ID
key_name                        = "service-key"       # Replace with your key pair name
# user_data                            = ""  # Base64 encoded user data script, if any
network_interfaces                   = []                       # List of network interfaces configurations
security_groups                      = ["sg-0904c5d1fde7777ff"] # Replace with your security group IDs
instance_initiated_shutdown_behavior = "stop"
block_device_mappings                = []         # List of block device mapping configurations
instance_type                        = "t2.micro" # Replace with your instance type

metadata_options = { # Replace with your metadata options
  http_endpoint               = "enabled",
  http_tokens                 = "optional",
  http_put_response_hop_limit = 1,
  http_protocol_ipv6          = "disabled",
  instance_metadata_tags      = "disabled"
}

enable_monitoring = true
tags = {
  Environment = "Dev",
  Project     = "Vault-OSS"
}

# Autoscaling group specific variables
ignore_desired_capacity_changes = false
use_name_prefix                 = false
use_mixed_instances_policy      = false
# availability_zones                   = ["us-east-1a", "us-east-1b"]    
vpc_zone_identifier       = ["subnet-0078ef2b40c2b7239", "subnet-009590ea08c8b49e4"]
min_size                  = 1
max_size                  = 3
desired_capacity          = 2
desired_capacity_type     = "units"
min_elb_capacity          = 1
wait_for_elb_capacity     = 120
wait_for_capacity_timeout = "10m"
default_cooldown          = 300
protect_from_scale_in     = false
load_balancers            = ["hadev-vault-load-balancer"]
target_group_arns         = ["arn:aws:elasticloadbalancing:us-east-1:200602878693:targetgroup/hadev-vault-load-balancer-tg/f1505d876ca28ab5"]
placement_group           = null
health_check_type         = "EC2"
health_check_grace_period = 300
force_delete              = false
termination_policies      = ["Default"]

instance_maintenance_policy = {
  min_healthy_percentage = 50
  max_healthy_percentage = 100
}
delete_timeout = "15m"


# Scaling policy specific variables
scaling_policies = {
  policy1 = {
    name                      = "scale-up-policy"
    adjustment_type           = "ChangeInCapacity"
    policy_type               = "SimpleScaling"
    estimated_instance_warmup = 300
    cooldown                  = 300
    min_adjustment_magnitude  = 1
    metric_aggregation_type   = "Average"
    step_adjustment = [
      {
        scaling_adjustment          = 2
        metric_interval_lower_bound = 0
        metric_interval_upper_bound = null
      }
    ]
  },
  # policy2 = {
  #   name                      = "scale-down-policy"
  #   adjustment_type           = "ChangeInCapacity"
  #   policy_type               = "SimpleScaling"
  #   estimated_instance_warmup = 300
  #   cooldown                  = 300
  #   min_adjustment_magnitude  = 1
  #   metric_aggregation_type   = "Average"
  #   step_adjustment = [
  #     {
  #       scaling_adjustment          = -1
  #       metric_interval_lower_bound = 0
  #       metric_interval_upper_bound = null
  #     }
  #   ]
  # }
}
create_scaling_policy = true   