# RDS Module Outputs

output "db_endpoint" {
  description = "RDS instance endpoint (host:port)"
  value       = aws_db_instance.notes_crud.endpoint
}

output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.notes_crud.id
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.notes_crud.arn
}

output "db_arn" {
  description = "RDS instance ARN (alias)"
  value       = aws_db_instance.notes_crud.arn
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.notes_crud.name
}

output "db_port" {
  description = "RDS instance port"
  value       = aws_db_instance.notes_crud.port
}

output "db_instance_status" {
  description = "RDS instance status"
  value       = aws_db_instance.notes_crud.status
}