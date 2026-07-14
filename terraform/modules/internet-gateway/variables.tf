variable "vpc_id" {
  description = "The ID of the VPC to attach the Internet Gateway to"
  type        = string
}

variable "environment" {
  description = "The environment name for resource tagging"
  type        = string

  validation {
    condition     = length(var.environment) > 0
    error_message = "Environment name must not be empty."
  }
}
