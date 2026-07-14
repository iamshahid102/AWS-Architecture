output "eip_id" {
  description = "The ID of the Elastic IP allocation"
  value       = aws_eip.nat.id
}

output "eip_allocation_id" {
  description = "The allocation ID of the Elastic IP (for NAT Gateway)"
  value       = aws_eip.nat.allocation_id
}

output "eip_public_ip" {
  description = "The public IP address of the Elastic IP"
  value       = aws_eip.nat.public_ip
}
