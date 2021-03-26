data "aws_iam_role" "node" {
  name = var.node_role_name
}

data "aws_subnet_ids" "cluster" {
  vpc_id = var.vpc_id
}

resource "aws_eks_node_group" "workers" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.cluster_name}-workers"
  node_role_arn   = data.aws_iam_role.node.arn
  subnet_ids      = data.aws_subnet_ids.cluster.ids

  instance_types = [var.instance_type]
  disk_size      = var.disk_size

  scaling_config {
    desired_size = var.desired_node_count
    max_size     = var.desired_node_count * 2
    min_size     = 1
  }

  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size,
      scaling_config[0].max_size,
    ]
  }
}
