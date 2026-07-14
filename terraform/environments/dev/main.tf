# ============================================================
# Networking + Compute Infrastructure - Notes CRUD Application
# Phase 1: Networking (completed)
# Phase 2: Security Groups, IAM, EC2 Launch Template
# ============================================================

# Fetch availability zones for the current region
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

# -----------------------------------------------------------
# VPC
# -----------------------------------------------------------
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr    = var.vpc_cidr
  environment = var.environment
}

# -----------------------------------------------------------
# Internet Gateway
# -----------------------------------------------------------
module "internet_gateway" {
  source = "../../modules/internet-gateway"

  vpc_id      = module.vpc.vpc_id
  environment = var.environment
}

# -----------------------------------------------------------
# Subnets
# -----------------------------------------------------------
module "subnets" {
  source = "../../modules/subnet"

  vpc_id                = module.vpc.vpc_id
  environment           = var.environment
  availability_zones    = local.azs
  public_subnet_a_cidr  = var.public_subnet_a_cidr
  public_subnet_b_cidr  = var.public_subnet_b_cidr
  private_subnet_a_cidr = var.private_subnet_a_cidr
  private_subnet_b_cidr = var.private_subnet_b_cidr
}

# -----------------------------------------------------------
# Elastic IP (for NAT Gateway) - conditional
# -----------------------------------------------------------
module "elastic_ip" {
  source = "../../modules/elastic-ip"
  count  = var.enable_nat_gateway ? 1 : 0

  environment = var.environment
}

# -----------------------------------------------------------
# NAT Gateway (deployed in Public Subnet A) - conditional
# -----------------------------------------------------------
module "nat_gateway" {
  source = "../../modules/nat-gateway"
  count  = var.enable_nat_gateway ? 1 : 0

  subnet_id     = module.subnets.public_subnet_a_id
  allocation_id = module.elastic_ip[0].eip_allocation_id
  environment   = var.environment
}

# -----------------------------------------------------------
# Route Tables
# -----------------------------------------------------------
module "route_tables" {
  source = "../../modules/route-table"

  vpc_id = module.vpc.vpc_id
  igw_id = module.internet_gateway.igw_id

  nat_gateway_id   = null
  create_nat_route = false

  public_subnet_ids  = module.subnets.public_subnet_ids
  private_subnet_ids = module.subnets.private_subnet_ids

  environment = var.environment
}

# ============================================================
# PHASE 2: Security Groups, IAM, EC2 Launch Template
# ============================================================

# -----------------------------------------------------------
# Security Groups
# Creates: ALB SG, EC2 SG, RDS SG
# -----------------------------------------------------------
module "security_group" {
  source = "../../modules/security-group"

  vpc_id            = module.vpc.vpc_id
  environment       = var.environment
  owner             = var.owner
  app_port          = var.app_port
  ssh_allowed_cidrs = var.ssh_allowed_cidrs
}

# -----------------------------------------------------------
# Application Load Balancer
# -----------------------------------------------------------
module "alb" {
  source = "../../modules/alb"

  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.subnets.public_subnet_ids
  alb_security_group_id = module.security_group.alb_security_group_id
  environment           = var.environment
  owner                 = var.owner
  acm_certificate_arn   = module.acm.certificate_arn
}

# -----------------------------------------------------------
# ACM Certificate (DNS Validation via Route 53)
# -----------------------------------------------------------
module "acm" {
  source = "../../modules/acm"

  domain_name    = var.domain_name
  hosted_zone_id = var.hosted_zone_id
  environment    = var.environment
  owner          = var.owner
}

# -----------------------------------------------------------
# IAM Role, Policy Attachments, Instance Profile
# For EC2 instances (CloudWatch Agent, SSM, EC2 Read, Logs)
# -----------------------------------------------------------
module "iam" {
  source = "../../modules/iam"

  environment                = var.environment
  owner                      = var.owner
  aws_region                 = var.aws_region
  aws_account_id             = var.aws_account_id
  cloudwatch_agent_s3_bucket = var.cloudwatch_agent_s3_bucket
}

# -----------------------------------------------------------
# EC2 Launch Template
# Ubuntu 24.04 LTS, t3.micro, Node.js LTS, PM2, CloudWatch Agent, SSM Agent
# -----------------------------------------------------------
module "ec2" {
  source = "../../modules/ec2"

  environment                       = var.environment
  owner                             = var.owner
  aws_region                        = var.aws_region
  instance_type                     = var.instance_type
  subnet_id                         = module.subnets.public_subnet_a_id
  security_group_ids                = [module.security_group.ec2_security_group_id]
  instance_profile_arn              = module.iam.instance_profile_arn
  key_name                          = var.key_name
  app_port                          = var.app_port
  node_version                      = var.node_version
  enable_cloudwatch_agent           = var.enable_cloudwatch_agent
  enable_ssm_agent                  = var.enable_ssm_agent
  root_volume_size                  = var.root_volume_size
  root_volume_type                  = var.root_volume_type
  root_volume_delete_on_termination = var.root_volume_delete_on_termination
  root_volume_encrypted             = var.root_volume_encrypted
  root_volume_kms_key_id            = var.root_volume_kms_key_id
  associate_public_ip               = var.associate_public_ip
  cloudwatch_agent_s3_bucket        = var.cloudwatch_agent_s3_bucket
  github_repo                       = var.github_repo
  github_branch                     = var.github_branch
  domain_name                       = var.domain_name
  ssl_email                         = var.ssl_email
  create_instance                   = var.create_instance
  instance_name                     = var.instance_name
}

# ============================================================
# PHASE 3: RDS Database (PostgreSQL)
# Free Tier: db.t3.micro, Single-AZ, 20GB gp3, private subnets
# ============================================================

# -----------------------------------------------------------
# RDS Database
# -----------------------------------------------------------
module "rds" {
  source = "../../modules/rds"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.subnets.private_subnet_ids
  security_group_ids = [module.security_group.rds_security_group_id]
  environment        = var.environment
  owner              = var.owner

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_type            = "gp3"
  multi_az                = false
  publicly_accessible     = false
  backup_retention_period = 1
  deletion_protection     = false
  engine_version          = "15.17"
}

# ============================================================
# PHASE 4: Auto Scaling Group
# Free Tier: min=1, max=1, desired=1 (single instance)
# ============================================================

# -----------------------------------------------------------
# Auto Scaling Group
# -----------------------------------------------------------
module "autoscaling" {
  source = "../../modules/autoscaling"

  vpc_zone_identifier = module.subnets.public_subnet_ids
  environment         = var.environment
  owner               = var.owner

  launch_template_id      = module.ec2.launch_template_id
  launch_template_version = module.ec2.launch_template_latest_version

  min_size         = 2
  max_size         = 2
  desired_capacity = 2

  # Health checks
  health_check_type         = "ELB"
  health_check_grace_period = 300

  # ALB target group attachment
  target_group_arns = [module.alb.target_group_arn]
}

# -----------------------------------------------------------
# Route 53 Alias Record for Domain -> ALB
# -----------------------------------------------------------
resource "aws_route53_record" "domain_alias" {
  count = var.domain_name != "" ? 1 : 0

  name    = var.domain_name
  type    = "A"
  zone_id = var.hosted_zone_id

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}
