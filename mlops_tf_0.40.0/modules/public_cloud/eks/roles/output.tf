output "cluster_role_name" {
  value       = aws_iam_role.cluster.name
  description = "Name of the role created for EKS."

  # The role is useless without it's attached policies, so we want to wait
  # before attachments are ready.
  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster-AmazonEKSServicePolicy,
  ]

}

output "cluster_node_role_name" {
  value       = aws_iam_role.node.name
  description = "Name of the role created for EKS worker nodes."


  # The role is useless without it's attached policies, so we want to wait
  # before attachments are ready.
  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
  ]
}
