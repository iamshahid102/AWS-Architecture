# ============================================================
# IAM Module Outputs
# ============================================================

output "iam_role_name" {
  description = "Name of the IAM role for EC2 instances"
  value       = aws_iam_role.ec2_instance.name
}

output "iam_role_arn" {
  description = "ARN of the IAM role for EC2 instances"
  value       = aws_iam_role.ec2_instance.arn
}

output "iam_role_id" {
  description = "ID of the IAM role for EC2 instances"
  value       = aws_iam_role.ec2_instance.id
}

output "instance_profile_name" {
  description = "Name of the IAM instance profile for EC2 instances"
  value       = aws_iam_instance_profile.ec2_instance.name
}

output "instance_profile_arn" {
  description = "ARN of the IAM instance profile for EC2 instances"
  value       = aws_iam_instance_profile.ec2_instance.arn
}

output "instance_profile_id" {
  description = "ID of the IAM instance profile for EC2 instances"
  value       = aws_iam_instance_profile.ec2_instance.id
}

output "iam_role_policy_name" {
  description = "Name of the inline policy attached to the IAM role"
  value       = aws_iam_role_policy.ec2_instance.name
}