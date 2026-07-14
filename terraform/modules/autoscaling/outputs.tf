# Auto Scaling Group Module Outputs

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.notes_crud.name
}

output "asg_arn" {
  description = "Auto Scaling Group ARN"
  value       = aws_autoscaling_group.notes_crud.arn
}

output "asg_desired_capacity" {
  description = "Desired capacity"
  value       = aws_autoscaling_group.notes_crud.desired_capacity
}

output "asg_min_size" {
  description = "Minimum size"
  value       = aws_autoscaling_group.notes_crud.min_size
}

output "asg_max_size" {
  description = "Maximum size"
  value       = aws_autoscaling_group.notes_crud.max_size
}