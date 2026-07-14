# ============================================================
# Infrastructure Outputs - Notes CRUD Application
# ============================================================

# -----------------------------------------------------------
# VPC
# -----------------------------------------------------------
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = module.vpc.vpc_arn
}

# -----------------------------------------------------------
# Subnets
# -----------------------------------------------------------
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.subnets.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.subnets.private_subnet_ids
}

output "public_subnet_a_id" {
  description = "The ID of public subnet A"
  value       = module.subnets.public_subnet_a_id
}

output "public_subnet_b_id" {
  description = "The ID of public subnet B"
  value       = module.subnets.public_subnet_b_id
}

output "private_subnet_a_id" {
  description = "The ID of private subnet A"
  value       = module.subnets.private_subnet_a_id
}

output "private_subnet_b_id" {
  description = "The ID of private subnet B"
  value       = module.subnets.private_subnet_b_id
}

# -----------------------------------------------------------
# Internet Gateway
# -----------------------------------------------------------
output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = module.internet_gateway.igw_id
}

# -----------------------------------------------------------
# NAT Gateway
# -----------------------------------------------------------
output "nat_gateway_id" {
  description = "The ID of the NAT Gateway (empty if NAT Gateway not enabled)"
  value       = var.enable_nat_gateway ? module.nat_gateway[0].nat_gateway_id : ""
}

output "nat_gateway_public_ip" {
  description = "The public IP address of the NAT Gateway (empty if NAT Gateway not enabled)"
  value       = var.enable_nat_gateway ? module.nat_gateway[0].nat_gateway_public_ip : ""
}

# -----------------------------------------------------------
# Elastic IP
# -----------------------------------------------------------
output "nat_eip_public_ip" {
  description = "The public IP of the NAT Gateway Elastic IP (empty if NAT Gateway not enabled)"
  value       = var.enable_nat_gateway ? module.elastic_ip[0].eip_public_ip : ""
}

# -----------------------------------------------------------
# Route Tables
# -----------------------------------------------------------
output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = module.route_tables.public_route_table_id
}

output "private_route_table_id" {
  description = "The ID of the private route table"
  value       = module.route_tables.private_route_table_id
}

# -----------------------------------------------------------
# Availability Zones
# -----------------------------------------------------------
output "availability_zones" {
  description = "The availability zones used for subnet deployment"
  value       = local.azs
}

# ============================================================
# PHASE 2 OUTPUTS: Security Groups, IAM, EC2 Launch Template
# ============================================================

# -----------------------------------------------------------
# Security Groups
# -----------------------------------------------------------
output "alb_security_group_id" {
  description = "Security Group ID for the Application Load Balancer"
  value       = module.security_group.alb_security_group_id
}

output "alb_security_group_arn" {
  description = "Security Group ARN for the Application Load Balancer"
  value       = module.security_group.alb_security_group_arn
}

output "ec2_security_group_id" {
  description = "Security Group ID for EC2 instances"
  value       = module.security_group.ec2_security_group_id
}

output "ec2_security_group_arn" {
  description = "Security Group ARN for EC2 instances"
  value       = module.security_group.ec2_security_group_arn
}

output "rds_security_group_id" {
  description = "Security Group ID for RDS PostgreSQL database"
  value       = module.security_group.rds_security_group_id
}

output "rds_security_group_arn" {
  description = "Security Group ARN for RDS PostgreSQL database"
  value       = module.security_group.rds_security_group_arn
}

output "all_security_group_ids" {
  description = "Map of all security group IDs for easy reference"
  value       = module.security_group.all_security_group_ids
}

output "all_security_group_arns" {
  description = "Map of all security group ARNs for easy reference"
  value       = module.security_group.all_security_group_arns
}

# -----------------------------------------------------------
# IAM
# -----------------------------------------------------------
output "iam_role_name" {
  description = "Name of the IAM role for EC2 instances"
  value       = module.iam.iam_role_name
}

output "iam_role_arn" {
  description = "ARN of the IAM role for EC2 instances"
  value       = module.iam.iam_role_arn
}

output "iam_role_id" {
  description = "ID of the IAM role for EC2 instances"
  value       = module.iam.iam_role_id
}

output "instance_profile_name" {
  description = "Name of the IAM instance profile for EC2 instances"
  value       = module.iam.instance_profile_name
}

output "instance_profile_arn" {
  description = "ARN of the IAM instance profile for EC2 instances"
  value       = module.iam.instance_profile_arn
}

output "instance_profile_id" {
  description = "ID of the IAM instance profile for EC2 instances"
  value       = module.iam.instance_profile_id
}

output "iam_role_policy_name" {
  description = "Name of the inline policy attached to the IAM role"
  value       = module.iam.iam_role_policy_name
}

# -----------------------------------------------------------
# EC2 Launch Template
# -----------------------------------------------------------
output "launch_template_id" {
  description = "Launch Template ID"
  value       = module.ec2.launch_template_id
}

output "launch_template_name" {
  description = "Launch Template Name"
  value       = module.ec2.launch_template_name
}

output "launch_template_latest_version" {
  description = "Latest version of the Launch Template"
  value       = module.ec2.launch_template_latest_version
}

output "launch_template_default_version" {
  description = "Default version of the Launch Template"
  value       = module.ec2.launch_template_default_version
}

output "launch_template_arn" {
  description = "Launch Template ARN"
  value       = module.ec2.launch_template_arn
}

output "ami_id" {
  description = "Ubuntu 24.04 AMI ID used in launch template"
  value       = module.ec2.ami_id
}

output "ami_name" {
  description = "Ubuntu 24.04 AMI Name"
  value       = module.ec2.ami_name
}

output "instance_type" {
  description = "Instance type used in launch template"
  value       = module.ec2.instance_type
}

# ============================================================
# PHASE 3 OUTPUTS: RDS Database
# ============================================================

output "rds_instance_id" {
  description = "RDS Instance Identifier"
  value       = module.rds.db_instance_id
}

output "rds_endpoint" {
  description = "RDS Instance Endpoint (host:port)"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "rds_port" {
  description = "RDS Instance Port"
  value       = module.rds.db_port
}

output "rds_arn" {
  description = "RDS Instance ARN"
  value       = module.rds.db_arn
}

# ============================================================
# PHASE 4 OUTPUTS: EC2 Instance + Elastic IP (100% Free Tier)
# ============================================================

output "instance_id" {
  description = "EC2 Instance ID"
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "EC2 Instance Public IP (without EIP)"
  value       = module.ec2.instance_public_ip
}

output "instance_private_ip" {
  description = "EC2 Instance Private IP"
  value       = module.ec2.instance_private_ip
}

output "eip_public_ip" {
  description = "Elastic IP for EC2 instance (static public IP)"
  value       = aws_eip.notes_crud.public_ip
}

output "application_url" {
  description = "Application URL (HTTP via Elastic IP)"
  value       = "http://${aws_eip.notes_crud.public_ip}"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i notes_app.pem ubuntu@${aws_eip.notes_crud.public_ip}"
}