variable "prefix" {
  description = "What prefix will be used for the resources used for the demo."
}

locals {
  cluster_name = "${var.prefix}-cluster"
}

resource "aws_eks_cluster" "demo" {
  name     = local.cluster_name
  role_arn = aws_iam_role.master.arn

  vpc_config {
    security_group_ids      = [aws_security_group.cluster.id]
    subnet_ids              = aws_subnet.demo[*].id
    endpoint_private_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster-AmazonEKSServicePolicy,
  ]

  timeouts {
    create = "60m"
    delete = "60m"
  }

}

output "cluster_name" {
  value = local.cluster_name
}

output "kubernetes_host" {
  value      = aws_eks_cluster.demo.endpoint
  depends_on = [aws_eks_cluster.demo]
}

output "kubernetes" {
  value = {
    endpoint = aws_eks_cluster.demo.endpoint
    token    = data.aws_eks_cluster_auth.cluster_auth.token
    ca_data  = aws_eks_cluster.demo.certificate_authority[0].data
  }

  depends_on = [
    aws_eks_cluster.demo,
    null_resource.cluster_join,
  ]
  sensitive = true
}
