# Auto Scaling Group Module Variables

variable "launch_template_id" {
  type        = string
  description = "Launch Template ID"
}

variable "launch_template_version" {
  type        = string
  description = "Launch Template version"
  default     = "$Latest"
}

variable "vpc_zone_identifier" {
  type        = list(string)
  description = "Subnet IDs for ASG (public subnets for direct internet access)"
}

variable "target_group_arns" {
  type        = list(string)
  description = "Target Group ARNs for ALB (empty if no ALB)"
  default     = []
}

variable "health_check_type" {
  type        = string
  description = "Health check type (EC2 or ELB)"
  default     = "EC2"
}

variable "health_check_grace_period" {
  type        = number
  description = "Health check grace period in seconds"
  default     = 300
}

variable "min_size" {
  type        = number
  description = "Minimum ASG size (Free Tier: 1)"
  default     = 1
}

variable "max_size" {
  type        = number
  description = "Maximum ASG size (Free Tier: 1)"
  default     = 1
}

variable "desired_capacity" {
  type        = number
  description = "Desired capacity (Free Tier: 1)"
  default     = 1
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "owner" {
  type        = string
  description = "Owner tag"
  default     = "platform-team"
}