# ============================================================
# Application Load Balancer Module - Notes CRUD Application
# Free Tier: internet-facing ALB with HTTP listener (redirects to HTTPS if cert provided)
# ============================================================

locals {
  common_tags = {
    Environment = var.environment
    Project     = "notes-crud"
    ManagedBy   = "terraform"
    Owner       = var.owner
  }

  alb_name = "${var.environment}-notes-crud-alb"
  tg_name  = "${var.environment}-notes-crud-tg"
}

# -----------------------------------------------------------
# Application Load Balancer
# -----------------------------------------------------------
resource "aws_lb" "notes_crud" {
  name               = local.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = merge(local.common_tags, {
    Name = local.alb_name
  })
}

# -----------------------------------------------------------
# Target Group (HTTP, port 80, instance targets)
# -----------------------------------------------------------
resource "aws_lb_target_group" "notes_crud" {
  name        = local.tg_name
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200"
  }

  tags = merge(local.common_tags, {
    Name = local.tg_name
  })
}

# -----------------------------------------------------------
# HTTP Listener (port 80) -> Redirect to HTTPS when cert provided
# -----------------------------------------------------------
resource "aws_lb_listener" "http_redirect" {
  count              = var.acm_certificate_arn != "" ? 1 : 0
  load_balancer_arn  = aws_lb.notes_crud.arn
  port               = 80
  protocol           = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# -----------------------------------------------------------
# HTTP Listener (port 80) -> Forward to Target Group (no cert)
# -----------------------------------------------------------
resource "aws_lb_listener" "http_forward" {
  count              = var.acm_certificate_arn == "" ? 1 : 0
  load_balancer_arn  = aws_lb.notes_crud.arn
  port               = 80
  protocol           = "HTTP"

  default_action {
    type = "forward"

    target_group_arn = aws_lb_target_group.notes_crud.arn
  }
}

# -----------------------------------------------------------
# HTTPS Listener (port 443) -> Target Group (conditional)
# -----------------------------------------------------------
resource "aws_lb_listener" "https" {
  count              = var.acm_certificate_arn != "" ? 1 : 0
  load_balancer_arn  = aws_lb.notes_crud.arn
  port               = 443
  protocol           = "HTTPS"
  ssl_policy         = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn    = var.acm_certificate_arn

  default_action {
    type = "forward"

    target_group_arn = aws_lb_target_group.notes_crud.arn
  }
}