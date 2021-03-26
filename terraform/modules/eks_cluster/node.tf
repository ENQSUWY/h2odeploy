variable "node_count" {
  # We won't use auto-scaling group as provisioning of the instance is more
  # straightforward.
  description = "How many nodes will be provisioned to join the cluster."
}

variable "node_instance_type" {
  description = "What instance type will be the worker nodes."
}

data "aws_ami" "eks_node" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.demo.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

resource "tls_private_key" "node_key_pair" {
  count = var.node_count

  algorithm = "RSA"
}

resource "aws_key_pair" "node_key_pair" {
  count = var.node_count

  key_name   = "${local.cluster_name}-node-${format("%02d", count.index)}-key"
  public_key = tls_private_key.node_key_pair[count.index].public_key_openssh
}

resource "aws_instance" "node" {
  count = var.node_count

  ami           = data.aws_ami.eks_node.id
  instance_type = var.node_instance_type

  tags = {
    Name                                          = "${local.cluster_name}-node-${format("%02d", count.index)}"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  }

  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.node.name
  subnet_id                   = aws_subnet.demo[0].id
  key_name                    = aws_key_pair.node_key_pair[count.index].id
  vpc_security_group_ids      = [aws_security_group.node.id]

  root_block_device {
    volume_size = 300
  }

  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
  ]

  lifecycle {
    create_before_destroy = true
  }

  timeouts {
    create = "360m"
  }
}
