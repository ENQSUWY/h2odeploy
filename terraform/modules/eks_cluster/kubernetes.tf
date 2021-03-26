variable "admin_arns" {
  description = "ARNs of AWS users to have admin access to the EKS cluster."
  type        = list(any)
  default     = []
}

variable "admin_role_arn" {
  description = "ARN of AWS role that will have admin access to the EKS cluster."
  default     = ""
}

data "aws_eks_cluster_auth" "cluster_auth" {
  name = local.cluster_name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.demo.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.demo.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
  load_config_file       = false
}

locals {
  admin_role_mapping_data = var.admin_role_arn == "" ? "" : <<YAML
- rolearn: ${var.admin_role_arn}
  username: kubectl-access-user
  groups:
    - system:masters
YAML
}

resource "kubernetes_config_map" "aws_auth_config_map" {
  depends_on = [aws_eks_cluster.demo]

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<YAML
- rolearn: ${aws_iam_role.node.arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
- rolearn: ${aws_iam_role.master.arn}
  username: kubectl-access-user
  groups:
    - system:masters
${local.admin_role_mapping_data}
YAML

    mapUsers = <<YAML
%{for admin in var.admin_arns~}
- userarn: ${admin}
  username: admin
  groups:
    - system:masters
%{endfor}
YAML
  }

}
