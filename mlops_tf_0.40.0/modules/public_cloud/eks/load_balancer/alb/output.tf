output "load_balancer_arn" {
  value       = aws_lb.lb.arn
  description = "ARN of the created load balancer."
}

output "load_balancer_name" {
  value       = aws_lb.lb.name
  description = "Name of the created load balancer."
}

output "target_group_arn" {
  value       = aws_lb_target_group.target.arn
  description = "ARN of the target group created for the load balancer."
}

output "security_group_id" {
  value       = aws_security_group.alb.id
  description = "ID of the security group created for the load balancer."
}
