# ALB Module Variables

variable "vpc_id" {
  type        = string
  description = "VPC ID for ALB deployment"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for ALB (must span 2 AZs)"
}

variable "alb_security_group_id" {
  type        = string
  description = "Security Group ID for ALB"
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

variable "acm_certificate_arn" {
  type        = string
  description = "ACM Certificate ARN for HTTPS (optional, enables HTTPS listener)"
  default     = ""
}