variable "subnet_id" {
  description = "The ID of the public subnet to deploy the NAT Gateway in"
  type        = string
}

variable "allocation_id" {
  description = "The allocation ID of the Elastic IP to associate with the NAT Gateway"
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
