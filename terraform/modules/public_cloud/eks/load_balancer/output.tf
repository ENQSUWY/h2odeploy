output "target_group_arn" {
  value       = module.alb.target_group_arn
  description = "ARN of the target group of the load balancer."
}

output "security_group_id" {
  value       = module.alb.security_group_id
  description = "ID of the security group created for the load balancer."
}
