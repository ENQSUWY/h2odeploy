output "worker_group_name" {
  value       = aws_eks_node_group.workers.node_group_name
  description = "Name of the created node group."
}

output "worker_group_arn" {
  value       = aws_eks_node_group.workers.arn
  description = "ARN of the created node group."
}

output "autoscaling_group_name" {
  value       = aws_eks_node_group.workers.resources[0].autoscaling_groups[0].name
  description = "Name of the autoscaling group created for the node group."
}
