variable "vpc_id" {
  description = "VPC ID where route tables will be created"
  type        = string

  validation {
    condition     = can(regex("^vpc-[0-9a-f]{8,}$", var.vpc_id))
    error_message = "VPC ID must be a valid VPC identifier (e.g., vpc-0123456789abcdef0)."
  }
}

variable "igw_id" {
  description = "Internet Gateway ID for public route"
  type        = string

  validation {
    condition     = can(regex("^igw-[0-9a-f]{8,}$", var.igw_id))
    error_message = "IGW ID must be a valid Internet Gateway identifier."
  }
}

variable "nat_gateway_id" {
  description = "NAT Gateway ID for private route (optional - set to null to disable NAT Gateway route)"
  type        = string
  default     = null
}

variable "create_nat_route" {
  description = "Whether to create the NAT Gateway route in the private route table"
  type        = bool
  default     = false
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for association"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "At least 2 public subnet IDs are required."
  }
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for association"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least 2 private subnet IDs are required."
  }
}

variable "environment" {
  description = "Environment name for resource tagging"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}