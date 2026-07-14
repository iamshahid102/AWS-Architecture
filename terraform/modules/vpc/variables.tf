variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR notation (e.g., 10.0.0.0/16)."
  }
}

variable "environment" {
  description = "The environment name for resource tagging (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = length(var.environment) > 0
    error_message = "Environment name must not be empty."
  }
}
