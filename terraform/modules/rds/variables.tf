# RDS Module Variables

variable "vpc_id" {
  type        = string
  description = "VPC ID for RDS deployment"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for RDS subnet group"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs for RDS instance"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

variable "owner" {
  type        = string
  description = "Owner tag"
  default     = "platform-team"
}

variable "db_name" {
  type        = string
  description = "Database name"
  default     = "notes_db"
}

variable "db_username" {
  type        = string
  description = "Database master username"
  default     = "postgres"
}

variable "db_password" {
  type        = string
  description = "Database master password (use AWS Secrets Manager in production)"
  sensitive   = true
}

variable "instance_class" {
  type        = string
  description = "RDS instance class (Free Tier: db.t3.micro)"
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  type        = number
  description = "Allocated storage in GB (Free Tier: <= 20)"
  default     = 20
}

variable "storage_type" {
  type        = string
  description = "Storage type (gp3 for Free Tier)"
  default     = "gp3"
}

variable "multi_az" {
  type        = bool
  description = "Multi-AZ deployment (Free Tier: false)"
  default     = false
}

variable "publicly_accessible" {
  type        = bool
  description = "Public accessibility (Free Tier: false)"
  default     = false
}

variable "backup_retention_period" {
  type        = number
  description = "Backup retention in days (Free Tier: 0-1)"
  default     = 1
}

variable "deletion_protection" {
  type        = bool
  description = "Deletion protection"
  default     = false
}

variable "engine_version" {
  type        = string
  description = "PostgreSQL engine version"
  default     = "16.3"
}