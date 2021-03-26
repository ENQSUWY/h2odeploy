data "aws_iam_role" "cluster" {
  name = var.cluster_role_name
}

data "aws_subnet_ids" "cluster" {
  vpc_id = var.vpc_id
}

resource "aws_eks_cluster" "cluster" {
  name     = var.name
  role_arn = data.aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = data.aws_subnet_ids.cluster.ids
    endpoint_private_access = true
  }

  timeouts {
    create = "60m"
    delete = "60m"
  }
}
