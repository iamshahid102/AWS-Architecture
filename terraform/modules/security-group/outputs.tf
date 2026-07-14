# ============================================================
# Security Group Module Outputs
# ============================================================

output "alb_security_group_id" {
  description = "Security Group ID for the Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "alb_security_group_arn" {
  description = "Security Group ARN for the Application Load Balancer"
  value       = aws_security_group.alb.arn
}

output "ec2_security_group_id" {
  description = "Security Group ID for EC2 instances"
  value       = aws_security_group.ec2.id
}

output "ec2_security_group_arn" {
  description = "Security Group ARN for EC2 instances"
  value       = aws_security_group.ec2.arn
}

output "rds_security_group_id" {
  description = "Security Group ID for RDS PostgreSQL database"
  value       = aws_security_group.rds.id
}

output "rds_security_group_arn" {
  description = "Security Group ARN for RDS PostgreSQL database"
  value       = aws_security_group.rds.arn
}

output "all_security_group_ids" {
  description = "Map of all security group IDs for easy reference"
  value = {
    alb = aws_security_group.alb.id
    ec2 = aws_security_group.ec2.id
    rds = aws_security_group.rds.id
  }
}

output "all_security_group_arns" {
  description = "Map of all security group ARNs for easy reference"
  value = {
    alb = aws_security_group.alb.arn
    ec2 = aws_security_group.ec2.arn
    rds = aws_security_group.rds.arn
  }
}