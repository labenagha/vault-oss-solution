resource "aws_lb" "ha-dev" {
  name                       = "hadev-vault-load-balancer"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.load_balancer_sg.id]
  subnets                    = ["subnet-0078ef2b40c2b7239", "subnet-009590ea08c8b49e4"]
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

resource "aws_lb_target_group" "vault_alb_tg" {
  name     = "hadev-vault-load-balancer-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id[0]

  health_check {
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.ha-dev.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vault_alb_tg.arn
  }
}

resource "aws_security_group" "load_balancer_sg" {
  name   = "load_balancer_sg"
  vpc_id = module.vpc.vpc_id[0]

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "load_balancer_sg"
  }
}
