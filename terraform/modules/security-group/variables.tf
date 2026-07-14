# ============================================================
# Security Group Module Variables
# ============================================================

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string

  validation {
    condition     = can(regex("^vpc-[0-9a-f]{8,}$", var.vpc_id))
    error_message = "VPC ID must be a valid VPC identifier (e.g., vpc-0123456789abcdef0)."
  }
}

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

variable "app_port" {
  description = "Application port for EC2 instances (default: 3000 for Node.js)"
  type        = number
  default     = 3000

  validation {
    condition     = var.app_port > 0 && var.app_port <= 65535
    error_message = "Application port must be between 1 and 65535."
  }
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed for SSH access to EC2 instances (restrict in production)"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for cidr in var.ssh_allowed_cidrs : can(cidrhost(cidr, 0))])
    error_message = "All SSH allowed CIDRs must be valid IPv4 CIDR notation."
  }
}