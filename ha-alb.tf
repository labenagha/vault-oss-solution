resource "aws_lb" "ha-dev" {
  name               = "hadev-vault-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.vpc.security_group_id]
  subnets            = ["subnet-0078ef2b40c2b7239", "subnet-009590ea08c8b49e4"]
  enable_deletion_protection = true

#   access_logs {
#     bucket  = aws_s3_bucket.lb_logs.id
#     prefix  = "ha-dev-lb"
#     enabled = true
#   }

  tags = {
    Environment = "dev"
  }
}

# resource "aws_lb_target_group" "vault_alb_tg" {
#   name        = "hadev-vault-load-balancer-tg"
#   port        = 80
#   protocol    = "HTTP"
#   vpc_id      = module.vpc.vpc_id[0]
# }