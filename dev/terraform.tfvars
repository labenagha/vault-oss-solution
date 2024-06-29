########################################
#### state bucket variables ############
########################################

state_bucket_policy_name = "TerraformStateManagementPolicy"
state_bucket_name        = "ha-vault-dev"


#######################################
##### AutoScaling Configurations ######
#######################################

create                      = true
name                        = "vault-dev-cluster-main"
launch_template_name        = "launch-template-vault-cluster-main"
launch_template_id          = null
create_iam_instance_profile = false

# You can set this to a specific version, `$Latest`, or `$Default`
launch_template_version = "$Latest"
# iam_instance_profile_name            = "ha-dev-iam-instance-asg"
# iam_role_name                        = "ha-dev-iam-role"
create_launch_template               = true
launch_template_use_name_prefix      = true
launch_template_description          = "ha-dev vault launch template description"
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
  Project     = "Vault-OSS"
}


#######################################
##### AutoScaling group ###############
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
wait_for_capacity_timeout       = "2m"
default_cooldown                = 300
protect_from_scale_in           = false
target_group_arns               = ["arn:aws:elasticloadbalancing:us-east-1:200602878693:targetgroup/hadev-vault-load-balancer-tg/236ad62260434695"]
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


port                  = 8200
log_level             = "info"
tls_cert              = <<EOF
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

tls_key               = <<EOF
-----BEGIN OPENSSH PRIVATE KEY-----
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
-----END OPENSSH PRIVATE KEY-----
EOF

s3_bucket             = "consul-vault-cluster-dev"
s3_bucket_region      = "us-east-1"
enable_s3_backend     = true
user                  = "vault"
aws_access_key_id     = null  # Set to null since it will be passed via GitHub Secrets
aws_secret_access_key = null  # Set to null since it will be passed via GitHub Secrets

