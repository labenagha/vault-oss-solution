################################################################################
# Launch template
################################################################################
variable "launch_template_name" {
  description = "Name of launch template to be created"
  type        = string
  default     = ""
}

variable "name" {
  description = "Name used across the resources created"
  type        = string
}

variable "launch_template_id" {
  description = "ID of an existing launch template to be used (created outside of this module)"
  type        = string
  default     = null
}

variable "create_iam_instance_profile" {
  description = "Determines whether an IAM instance profile is created or to use an existing IAM instance profile"
  type        = bool
  default     = false
}

variable "launch_template_version" {
  description = "Launch template version. Can be version number, `$Latest`, or `$Default`"
  type        = string
  default     = null
}

variable "iam_instance_profile_arn" {
  description = "Amazon Resource Name (ARN) of an existing IAM instance profile. Used when `create_iam_instance_profile` = `false`"
  type        = string
  default     = null
}

variable "iam_instance_profile_name" {
  description = "The name of the IAM instance profile to be created (`create_iam_instance_profile` = `true`) or existing (`create_iam_instance_profile` = `false`)"
  type        = string
  default     = null
}

variable "iam_role_name" {
  description = "Name to use on IAM role created"
  type        = string
  default     = null
}

variable "create" {
  description = "Determines whether to create autoscaling group or not"
  type        = bool
  default     = true
}

variable "create_launch_template" {
  description = "Determines whether to create launch template or not"
  type        = bool
  default     = true
}

variable "launch_template_use_name_prefix" {
  description = "Determines whether to use `launch_template_name` as is or create a unique name beginning with the `launch_template_name` as the prefix"
  type        = bool
  default     = true
}

variable "launch_template_description" {
  description = "Description of the launch template"
  type        = string
  default     = null
}

variable "ebs_optimized" {
  description = "If true, the launched EC2 instance will be EBS-optimized"
  type        = bool
  default     = null
}

variable "image_id" {
  description = "The AMI from which to launch the instance"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "The key name that should be used for the instance"
  type        = string
  default     = null
}

variable "network_interfaces" {
  description = "Customize network interfaces to be attached at instance boot time"
  type        = list(any)
  default     = []
}

variable "security_groups" {
  description = "A list of security group IDs to associate"
  type        = list(string)
  default     = []
}

variable "instance_initiated_shutdown_behavior" {
  description = "Shutdown behavior for the instance. Can be `stop` or `terminate`. (Default: `stop`)"
  type        = string
  default     = null
}

variable "block_device_mappings" {
  description = "Specify volumes to attach to the instance besides the volumes specified by the AMI"
  type        = list(any)
  default     = []
}

variable "instance_type" {
  description = "The type of the instance. If present then `instance_requirements` cannot be present"
  type        = string
  default     = null
}

variable "metadata_options" {
  description = "Customize the metadata options for the instance"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}

variable "enable_monitoring" {
  description = "Enables/disables detailed monitoring"
  type        = bool
  default     = true
}

variable "state_bucket_policy_name" {
  type = string
}

variable "state_bucket_name" {
  type = string
}

variable "ACCESS_TOKEN" {
  description = "GITHUB ACCESS TOKEN Used for authentication fo gh runner install"
  type        = string
}

variable "public_key" {
  description = "SSH key to be used `rsa` generated"
  type        = string
}

variable "RUNNER_VERSION" {
  type    = string
  default = "2.317.0"
}

variable "RUNNER_SHA" {
  type = string
}


variable "min_size" {
  description = "The minimum size of the autoscaling group"
  type        = number
  default     = null
}

variable "max_size" {
  description = "The maximum size of the autoscaling group"
  type        = number
  default     = null
}

variable "desired_capacity" {
  description = "The number of Amazon EC2 instances that should be running in the autoscaling group"
  type        = number
  default     = null
}

variable "desired_capacity_type" {
  description = "The unit of measurement for the value specified for desired_capacity. Supported for attribute-based instance type selection only. Valid values: `units`, `vcpu`, `memory-mib`."
  type        = string
  default     = null
}

variable "min_elb_capacity" {
  description = "Setting this causes Terraform to wait for this number of instances to show up healthy in the ELB only on creation. Updates will not wait on ELB instance number changes"
  type        = number
  default     = null
}

variable "wait_for_elb_capacity" {
  description = "Setting this will cause Terraform to wait for exactly this number of healthy instances in all attached load balancers on both create and update operations. Takes precedence over `min_elb_capacity` behavior."
  type        = number
  default     = null
}

variable "wait_for_capacity_timeout" {
  description = "A maximum duration that Terraform should wait for ASG instances to be healthy before timing out. (See also Waiting for Capacity below.) Setting this to '0' causes Terraform to skip all Capacity Waiting behavior."
  type        = string
  default     = null
}

variable "default_cooldown" {
  description = "The amount of time, in seconds, after a scaling activity completes before another scaling activity can start"
  type        = number
  default     = null
}

variable "protect_from_scale_in" {
  description = "Allows setting instance protection. The autoscaling group will not select instances with this setting for termination during scale in events."
  type        = bool
  default     = false
}

variable "target_group_arns" {
  description = "A set of `aws_alb_target_group` ARNs, for use with Application or Network Load Balancing"
  type        = list(string)
  default     = []
}

variable "placement_group" {
  description = "The name of the placement group into which you'll launch your instances, if any"
  type        = string
  default     = null
}

variable "health_check_type" {
  description = "`EC2` or `ELB`. Controls how health checking is done"
  type        = string
  default     = null
}

variable "health_check_grace_period" {
  description = "Time (in seconds) after instance comes into service before checking health"
  type        = number
  default     = null
}

variable "force_delete" {
  description = "Allows deleting the Auto Scaling Group without waiting for all instances in the pool to terminate. You can force an Auto Scaling Group to delete even if it's in the process of scaling a resource. Normally, Terraform drains all the instances before deleting the group. This bypasses that behavior and potentially leaves resources dangling"
  type        = bool
  default     = null
}

variable "termination_policies" {
  description = "A list of policies to decide how the instances in the Auto Scaling Group should be terminated. The allowed values are `OldestInstance`, `NewestInstance`, `OldestLaunchConfiguration`, `ClosestToNextInstanceHour`, `OldestLaunchTemplate`, `AllocationStrategy`, `Default`"
  type        = list(string)
  default     = []
}

variable "instance_maintenance_policy" {
  description = "If this block is configured, add a instance maintenance policy to the specified Auto Scaling group"
  type        = map(any)
  default     = {}
}

variable "delete_timeout" {
  description = "Delete timeout to wait for destroying autoscaling group"
  type        = string
  default     = null
}

variable "use_name_prefix" {
  description = "Determines whether to use `name` as is or create a unique name beginning with the `name` as the prefix"
  type        = bool
  default     = true
}

variable "ignore_desired_capacity_changes" {
  description = "Determines whether the `desired_capacity` value is ignored after initial apply. See README note for more details"
  type        = bool
  default     = false
}

variable "use_mixed_instances_policy" {
  description = "Determines whether to use a mixed instances policy in the autoscaling group or not"
  type        = bool
  default     = false
}

# variable "availability_zones" {
#   description = "A list of one or more availability zones for the group. Used for EC2-Classic and default subnets when not specified with `vpc_zone_identifier` argument. Conflicts with `vpc_zone_identifier`"
#   type        = list(string)
#   default     = null
# }

variable "vpc_zone_identifier" {
  description = "A list of subnet IDs to launch resources in. Subnets automatically determine which availability zones the group will reside. Conflicts with `availability_zones`"
  type        = list(string)
  default     = null
}

################################################################################
# Autoscaling policy
################################################################################

variable "create_scaling_policy" {
  description = "Determines whether to create target scaling policy schedule or not"
  type        = bool
  default     = true
}

variable "scaling_policies" {
  description = "Map of target scaling policy schedule to create"
  type        = any
  default     = {}
}

variable "tls_cert_file" {
  description = "Path to the TLS certificate file"
  default     = <<EOF
-----BEGIN CERTIFICATE-----
MIIGQDCCBSigAwIBAgIRAKEtRTiQCRcNftHqS7m6w+YwDQYJKoZIhvcNAQELBQAw
gY8xCzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAO
BgNVBAcTB1NhbGZvcmQxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDE3MDUGA1UE
AxMuU2VjdGlnbyBSU0EgRG9tYWluIFZhbGlkYXRpb24gU2VjdXJlIFNlcnZlciBD
QTAeFw0yNDAyMTEwMDAwMDBaFw0yNDExMTcyMzU5NTlaMBsxGTAXBgNVBAMTEHRz
cmxlYXJuaW5nLmxpbmswggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCu
jEOatkrgPPpGQWzJKO3QWcqjnvIvFrGgf24U6hCoMbsWP2f/fzZXWKT8r3P8NqHN
YE9GDdzn0P6LfwygR6seNa+dY8p++7XbQZnQDRfLBftAkGUgv/vWHE0PKaLcIq6D
6ILYUStZPSQB1nyiuJTjm8o4nWhK11QoAFTwzghCwg1ZCXvsyD0OVmsRLH94D9jQ
Rus4B5VYewatYwmDS3NIOGjJpOnnKlTbG5yxsFDzOvGRFBJhmez9pYPHXhY0aSD8
8l+KdF8zfZf5TX6rI+f2vz5ATWG7XlcwcLocs7OmVatt1A+e3D3C2ibhTGFov5Dl
9uIuvcoIETOf25YL7ZIxAgMBAAGjggMIMIIDBDAfBgNVHSMEGDAWgBSNjF7EVK2K
4Xfpm/mbBeG4AY1h4TAdBgNVHQ4EFgQUi3m5uyZ1rmxuygQ+37y/Os4MKgYwDgYD
VR0PAQH/BAQDAgWgMAwGA1UdEwEB/wQCMAAwHQYDVR0lBBYwFAYIKwYBBQUHAwEG
CCsGAQUFBwMCMEkGA1UdIARCMEAwNAYLKwYBBAGyMQECAgcwJTAjBggrBgEFBQcC
ARYXaHR0cHM6Ly9zZWN0aWdvLmNvbS9DUFMwCAYGZ4EMAQIBMIGEBggrBgEFBQcB
AQR4MHYwTwYIKwYBBQUHMAKGQ2h0dHA6Ly9jcnQuc2VjdGlnby5jb20vU2VjdGln
b1JTQURvbWFpblZhbGlkYXRpb25TZWN1cmVTZXJ2ZXJDQS5jcnQwIwYIKwYBBQUH
MAGGF2h0dHA6Ly9vY3NwLnNlY3RpZ28uY29tMDEGA1UdEQQqMCiCEHRzcmxlYXJu
aW5nLmxpbmuCFHd3dy50c3JsZWFybmluZy5saW5rMIIBfgYKKwYBBAHWeQIEAgSC
AW4EggFqAWgAdgB2/4g/Crb7lVHCYcz1h7o0tKTNuyncaEIKn+ZnTFo6dAAAAY2Z
FpZzAAAEAwBHMEUCIQC57mVlTPRo7zGW2fv8rVYHlcgwljZthrl7750TfA8+9wIg
Tu2P1npZtGKhVWKlDtYDIOHOCD7X1eQU5HUONIKJ8zMAdgA/F0tP1yJHWJQdZRyE
vg0S7ZA3fx+FauvBvyiF7PhkbgAAAY2ZFpe+AAAEAwBHMEUCIQCTKG13ylzxSyQ4
YqJDWp0ucfNKsp5rjWzW8cABtkDinwIgMmbly/12QtN5jO1pQstoaIFGP2FoW4Z9
nBWkTpqTSOoAdgDuzdBk1dsazsVct520zROiModGfLzs3sNRSFlGcR+1mwAAAY2Z
FpbAAAAEAwBHMEUCIEhpfriCjcsoPM0pJEp8WAuALENXpytC1wcIes9Vte6lAiEA
3Tppd8JEC4avA/uYrynSdVqdokdILvzJVEQtKuYWNiAwDQYJKoZIhvcNAQELBQAD
ggEBAASOgTO7iEN5WBlEr9IvXYPyzgmCOzZ2fVQwLMRrrsN9d6nyv+HbPDapN0jF
/zl/20a5HD96CtJS2HQ8qTe+CDESYLr1TxtEcosL4Bxni78898y3KeJ/X0VOKDKK
6cJ7FZY6S+u3MN53PHIlF7RyQ43GbUMNOWXTtkMxS8RzmBmlGtH3J8xHGVSx0LFh
6zNqEm1ZnNR0LYP2zQBwAZ18U29aIXdPbbRnMzrCVM2kpjjWSX1o+a8T2zIg/CSg
gJ61/kCnw580HYgjf0EvSsOiN6O1omqQpZLehHT9Av7razk8y65vlhBtxAIseUGf
w4jdfsYicJqaEOFATlqzJhvob9I=
-----END CERTIFICATE-----
EOF
}

variable "tls_key_file" {
  description = "Path to the TLS key file"
  default     = <<EOF
  -----BEGIN PRIVATE KEY-----
MIIEuwIBADANBgkqhkiG9w0BAQEFAASCBKUwggShAgEAAoIBAQCujEOatkrgPPpG
QWzJKO3QWcqjnvIvFrGgf24U6hCoMbsWP2f/fzZXWKT8r3P8NqHNYE9GDdzn0P6L
fwygR6seNa+dY8p++7XbQZnQDRfLBftAkGUgv/vWHE0PKaLcIq6D6ILYUStZPSQB
1nyiuJTjm8o4nWhK11QoAFTwzghCwg1ZCXvsyD0OVmsRLH94D9jQRus4B5VYewat
YwmDS3NIOGjJpOnnKlTbG5yxsFDzOvGRFBJhmez9pYPHXhY0aSD88l+KdF8zfZf5
TX6rI+f2vz5ATWG7XlcwcLocs7OmVatt1A+e3D3C2ibhTGFov5Dl9uIuvcoIETOf
25YL7ZIxAgMBAAECgf8raisZvP28VW5qyxsj1B2F4gLLb8PaGOrvE/Y6SkqaV/d3
MSfM6124z0Btf7Z5pTamWEfF3oZzonTg4/KTOA0RfO9eIzp0TmdaG2PTbwfb/g2t
OwnsSDqups6dihDYCeHrLVbEnZ8KmaQhhBfvR7nz/J8jAp2BZmdB2KAUxSpVo0Vn
Qw9Uewaykn9IxeQGHfS4T3pPrNbtP8E6Xwqxh74WMVtPDJJ1ld5gdI1nEv+wMoNZ
GbJYdrmQD9ShxQ+C6Epdm2F5QVNtpeZfla13dgrfSOg9BuVjIdIzB5fnZZCpHbtP
VvWIMfNdG3UaTg36HI2wU9pkr9Eu3G2WLUV6rrkCgYEA2199yzOPlpHnY3CvCBgj
jKlHnzYpbee5K1GzcZw/n5V9zquCv3USQdNNd0UnSrJNdZruZqS5ohsCIwMjN/M3
pHLPj6Yemt9YRw05evxNowPZOnj2taniXn2T+pyqTfh5U2qMJx0Jbn80aUvV9JCC
mLjBfgkfQdJF/P9ku+xgivkCgYEAy7DYIB8To0HXrqYjTvthrJgbJbnj+wHW8A4W
b71YrFScEtMHaAZRDUCZD2FfTpIn4BaojoFuu/QUep9xEswGwxsVDnzD7Zq1VakZ
idvpOqnRfjUo5ukQ/rQQvcHPbUnT7pK5TtcKD0EAnhV2mL1wAblLvLaYj138N73k
4O79FvkCgYBvHFywkTsG/nt+SFK+/Mr0scDPCTXOrvGA2W7T+lnXUHZaOVCN/JP0
tzujT2lpUgodqQ1a+8/yJU/dv/cUnaHvLx+mGHOj6b/irPYSLrx79rUOArqipJs9
VMmgw70WpOV+tJasMO7YAqHfO0PxDUi4ZcvLNH+abRB55jl1XXJAsQKBgHYiDWar
v17q2+UNs+KlxqMr4GrD4eX8ziSRdw+9OAVSWOZN/7ikGTPfaCXUaksOVxQO8Bke
FhPp3kqz2Ad3zuAu/8pUL+nI1SxmE0qyARUl0jspJ5ysRVADLMZw9hVDQSfXbqO7
8bihEXOdrReunpxRVAyRte9IKfRGLM0Lrjs5AoGBALACy+DMY0f6uQG6Jve8GT4d
YSPCQdEgZZ1xcoGGRlWS2dbEVx9CID49kYv5jqhMVOPOX2tB2p81md+f4UbK/ti4
RMgbcns1JsvI+IB4JTWnMmjSlUlzBmf8GciULcVhqdLySlcvDBla0URLqx9A5i1f
vp5I+W5Wu1805PCZ4Sl7
-----END PRIVATE KEY-----
EOF
}

variable "enable_auto_unseal" {
  description = "Enable AWS KMS auto unseal"
  type        = bool
}

variable "auto_unseal_kms_key_id" {
  description = "AWS KMS Key ID for auto unseal"
}

variable "auto_unseal_kms_key_region" {
  description = "AWS region for the KMS key"
}

variable "config_dir" {
  description = "Directory for Vault configuration"
  default     = "/etc/vault"
}

variable "bin_dir" {
  description = "Directory for Vault binary"
  default     = "/usr/local/bin"
}

variable "user" {
  description = "User to run Vault"
  default     = "vault"
}

variable "enable_s3_backend" {
  description = "Enable S3 backend for Vault storage"
  type        = bool
  default     = false
}

variable "s3_bucket" {
  description = "S3 bucket for Vault storage"
  default     = ""
}

variable "s3_bucket_path" {
  description = "S3 bucket path for Vault storage"
  default     = ""
}

variable "s3_bucket_region" {
  description = "AWS region for the S3 bucket"
  default     = ""
}

variable "account_id" {
  description = "AWS Account ID"
}

variable "role_name" {
  description = "IAM role name"
  default     = "VaultAdminRole"
}

variable "policy_arn" {
  description = "IAM policy ARN"
  default     = "arn:aws:iam::aws:policy/AdministratorAccess"
}

variable "session_name" {
  description = "IAM session name"
  default     = "VaultSession"
}

variable "default_port" {
  description = "Vault Default Port"
  type        = number
  default     = 8200
}