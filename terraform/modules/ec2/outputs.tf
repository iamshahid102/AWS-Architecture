# ============================================================
# EC2 Module Outputs
# ============================================================

output "launch_template_id" {
  description = "Launch Template ID"
  value       = aws_launch_template.notes_crud.id
}

output "launch_template_name" {
  description = "Launch Template Name"
  value       = aws_launch_template.notes_crud.name
}

output "launch_template_latest_version" {
  description = "Latest version of the Launch Template"
  value       = aws_launch_template.notes_crud.latest_version
}

output "launch_template_default_version" {
  description = "Default version of the Launch Template"
  value       = aws_launch_template.notes_crud.default_version
}

output "launch_template_arn" {
  description = "Launch Template ARN"
  value       = aws_launch_template.notes_crud.arn
}

output "ami_id" {
  description = "Ubuntu 24.04 AMI ID used in launch template"
  value       = data.aws_ami.ubuntu_2404.id
}

output "ami_name" {
  description = "Ubuntu 24.04 AMI Name"
  value       = data.aws_ami.ubuntu_2404.name
}

output "instance_type" {
  description = "Instance type used in launch template"
  value       = var.instance_type
}

# -----------------------------------------------------------
# EC2 Instance Outputs (when created)
# -----------------------------------------------------------
output "instance_id" {
  description = "EC2 Instance ID (empty if not created)"
  value       = var.create_instance ? aws_instance.notes_crud[0].id : ""
}

output "instance_arn" {
  description = "EC2 Instance ARN (empty if not created)"
  value       = var.create_instance ? aws_instance.notes_crud[0].arn : ""
}

output "instance_public_ip" {
  description = "EC2 Instance public IP (empty if not created)"
  value       = var.create_instance ? aws_instance.notes_crud[0].public_ip : ""
}

output "instance_private_ip" {
  description = "EC2 Instance private IP (empty if not created)"
  value       = var.create_instance ? aws_instance.notes_crud[0].private_ip : ""
}

output "instance_availability_zone" {
  description = "EC2 Instance availability zone (empty if not created)"
  value       = var.create_instance ? aws_instance.notes_crud[0].availability_zone : ""
}