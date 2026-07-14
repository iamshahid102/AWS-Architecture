output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "public_subnet_a_id" {
  description = "The ID of public subnet A"
  value       = aws_subnet.public_a.id
}

output "public_subnet_b_id" {
  description = "The ID of public subnet B"
  value       = aws_subnet.public_b.id
}

output "private_subnet_a_id" {
  description = "The ID of private subnet A"
  value       = aws_subnet.private_a.id
}

output "private_subnet_b_id" {
  description = "The ID of private subnet B"
  value       = aws_subnet.private_b.id
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = [aws_subnet.public_a.cidr_block, aws_subnet.public_b.cidr_block]
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = [aws_subnet.private_a.cidr_block, aws_subnet.private_b.cidr_block]
}

output "public_subnet_arns" {
  description = "List of public subnet ARNs"
  value       = [aws_subnet.public_a.arn, aws_subnet.public_b.arn]
}

output "private_subnet_arns" {
  description = "List of private subnet ARNs"
  value       = [aws_subnet.private_a.arn, aws_subnet.private_b.arn]
}
