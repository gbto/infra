locals {
  subnet_id = var.aws_subnet_public["public-rds-1"].availability_zone == aws_db_instance.postgresql.availability_zone ? var.aws_subnet_public["public-rds-1"].id : var.aws_subnet_public["public-rds-2"].id
}

resource "aws_lb" "rds" {
  name               = "nlb-expose-rds-${var.env}"
  internal           = false
  load_balancer_type = "network"
  subnets            = [local.subnet_id]

  enable_deletion_protection = false

  tags = {
    Environment = var.env
  }
}

resource "aws_lb_listener" "rds" {
  load_balancer_arn = aws_lb.rds.id
  port              = var.rds_port
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.rds.id
    type             = "forward"
  }
}

resource "aws_lb_target_group" "rds" {
  name          = "expose-rds-${var.env}"
  port          = var.rds_port
  protocol      = "TCP"
  target_type   = "ip"
  vpc_id        = var.vpc_id
  health_check {
    enabled     = true
    protocol    = "TCP"
  }
  tags = {
    Environment = var.env
  }
}

resource "aws_cloudwatch_metric_alarm" "rds-access" {
  alarm_name          = "rds-external-access-status"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/NetworkELB"
  period              = "60"
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "Monitoring RDS External Access"
  treat_missing_data  = "breaching"

  dimensions = {
    TargetGroup  = aws_lb_target_group.rds.arn_suffix
    LoadBalancer = aws_lb.rds.arn_suffix
  }
}
