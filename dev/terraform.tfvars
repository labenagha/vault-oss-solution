########################################
#### state bucket variables ############
########################################

state_bucket_policy_name = "TerraformStateManagementPolicy"
state_bucket_name        = "ha-vault-dev"


#######################################
##### AutoScaling Configurations ######
#######################################

create                               = true
name                                 = "ha-dev-vault"
launch_template_name                 = "ha-dev-launch-template"
launch_template_id                   = null  # Set to the existing launch template ID if any, otherwise leave as null
create_iam_instance_profile          = false  # Set to true if you need to create a new IAM instance profile
launch_template_version              = "$Latest"  # You can set this to a specific version, `$Latest`, or `$Default`
# iam_instance_profile_arn             = null  # Set the ARN of the existing IAM instance profile if `create_iam_instance_profile` is false
iam_instance_profile_name            = "ha-dev-iam-instance-profile"
iam_role_name                        = "ha-dev-iam-role"
create_launch_template               = true
launch_template_use_name_prefix      = true
launch_template_description          = "ha-dev launch template description"
ebs_optimized                        = true
image_id                             = "ami-04b70fa74e45c3917"  # Replace with your AMI ID
key_name                             = "ha-dev-key-pair"  # Replace with your key pair name
# user_data                            = ""  # Base64 encoded user data script, if any
network_interfaces                   = []  # List of network interfaces configurations
security_groups                      = ["sg-0904c5d1fde7777ff"]  # Replace with your security group IDs
instance_initiated_shutdown_behavior = "stop"
block_device_mappings                = []  # List of block device mapping configurations
instance_type                        = "t2.micro"  # Replace with your instance type

metadata_options                     = {  # Replace with your metadata options
  http_endpoint = "enabled",
  http_tokens = "optional",
  http_put_response_hop_limit = 1,
  http_protocol_ipv6 = "disabled",
  instance_metadata_tags = "disabled"
}
enable_monitoring                    = true
tags                                 = {
  Environment = "Dev",
  Project     = "Vault-OSS"
}

