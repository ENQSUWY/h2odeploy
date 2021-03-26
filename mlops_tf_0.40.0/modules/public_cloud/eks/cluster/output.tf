output "cluster_name" {
  value       = aws_eks_cluster.cluster.name
  description = "Name of the EKS cluster created."
}

output "kubernetes_endpoint" {
  value       = aws_eks_cluster.cluster.endpoint
  description = "Public endpoint to the Kubernetes API of the created EKS cluster."
}

output "security_group_id" {
  value       = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
  description = "ID of the security group associated with the created EKS cluster."
}
