# ALB Module Outputs

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.notes_crud.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.notes_crud.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.notes_crud.zone_id
}

output "target_group_arn" {
  description = "ARN of the Target Group"
  value       = aws_lb_target_group.notes_crud.arn
}

output "http_listener_arn" {
  description = "ARN of the HTTP Listener (redirect or forward)"
  value       = var.acm_certificate_arn != "" ? aws_lb_listener.http_redirect[0].arn : aws_lb_listener.http_forward[0].arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS Listener (conditional)"
  value       = var.acm_certificate_arn != "" ? aws_lb_listener.https[0].arn : ""
}