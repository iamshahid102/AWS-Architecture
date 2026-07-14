# ============================================================
# IAM Module Variables
# ============================================================

variable "environment" {
  description = "Environment name for resource naming and tagging"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Owner/team responsible for the resources"
  type        = string
  default     = "platform-team"

  validation {
    condition     = length(var.owner) > 0
    error_message = "Owner cannot be empty."
  }
}

variable "aws_region" {
  description = "AWS region for resource ARNs"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "AWS region must be a valid region identifier (e.g., ap-south-1, us-east-1)."
  }
}

variable "aws_account_id" {
  description = "AWS Account ID for resource ARNs"
  type        = string

  validation {
    condition     = can(regex("^\\d{12}$", var.aws_account_id))
    error_message = "AWS Account ID must be a 12-digit number."
  }
}

variable "cloudwatch_agent_s3_bucket" {
  description = "S3 bucket name for CloudWatch Agent configuration (if using S3)"
  type        = string
  default     = ""

  validation {
    condition     = var.cloudwatch_agent_s3_bucket == "" || can(regex("^[a-z0-9.-]+$", var.cloudwatch_agent_s3_bucket))
    error_message = "S3 bucket name must be valid (lowercase, numbers, dots, hyphens)."
  }
}