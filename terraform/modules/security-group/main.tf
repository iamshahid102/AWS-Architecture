# ============================================================
# Security Group Module - Notes CRUD Application
# Creates 3 security groups: ALB, EC2, RDS
# ============================================================

locals {
  common_tags = {
    Environment = var.environment
    Project     = "notes-crud"
    ManagedBy   = "terraform"
    Owner       = var.owner
  }

  alb_sg_name        = "${var.environment}-alb-sg"
  ec2_sg_name        = "${var.environment}-ec2-sg"
  rds_sg_name        = "${var.environment}-rds-sg"
  alb_sg_description = "Security group for Application Load Balancer"
  ec2_sg_description = "Security group for EC2 instances in Auto Scaling Group"
  rds_sg_description = "Security group for RDS PostgreSQL database"
}

# -----------------------------------------------------------
# ALB Security Group
# -----------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = local.alb_sg_name
  description = local.alb_sg_description
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = local.alb_sg_name
    Role = "alb"
  })
}

# -----------------------------------------------------------
# EC2 Security Group
# -----------------------------------------------------------
resource "aws_security_group" "ec2" {
  name        = local.ec2_sg_name
  description = local.ec2_sg_description
  vpc_id      = var.vpc_id

  # HTTP from Internet (Nginx on port 80)
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH Access
  ingress {
    description = "SSH from allowed CIDRs"

    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = var.ssh_allowed_cidrs
  }

  egress {
    description = "Outbound traffic"

    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = local.ec2_sg_name
    Role = "ec2"
  })
}

# -----------------------------------------------------------
# RDS Security Group
# -----------------------------------------------------------
resource "aws_security_group" "rds" {
  name        = local.rds_sg_name
  description = local.rds_sg_description
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL from EC2"

    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"

    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    description = "Outbound traffic"

    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = local.rds_sg_name
    Role = "rds"
  })
}
