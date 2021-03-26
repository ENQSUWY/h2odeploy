# Setup the AWS provider
#
# See <https://www.terraform.io/docs/providers/aws/index.html> for details.

# provider "aws" {
#   region = "us-west-2"
# }

locals {
  cluster_name = "example-cluster"
  domain       = "cluster.example.com"
}

module "vpc" {
  source = "../terraform/modules/public_cloud/eks/vpc"

  name = local.cluster_name
}

module "roles" {
  source = "../terraform/modules/public_cloud/eks/roles"

  name = local.cluster_name
}

module "cluster" {
  source = "../terraform/modules/public_cloud/eks/cluster"

  name = local.cluster_name

  vpc_id                 = module.vpc.id
  cluster_role_name      = module.roles.cluster_role_name
  cluster_node_role_name = module.roles.cluster_node_role_name
}

module "workers" {
  source = "../terraform/modules/public_cloud/eks/workers"

  cluster_name   = module.cluster.cluster_name
  vpc_id         = module.vpc.id
  node_role_name = module.roles.cluster_node_role_name

  desired_node_count = 2
  instance_type      = "t3a.large"
}


module "lb" {
  source = "../terraform/modules/public_cloud/eks/load_balancer"

  name = "${local.cluster_name}-router-alb"

  route_zone  = "h2o.ai."
  domain      = local.domain
  target_port = 80

  vpc_id = module.vpc.id
}

module "attach_lb" {
  source = "../terraform/modules/public_cloud/eks/attach_load_balancer"

  port                            = 80
  autoscaling_group_name          = module.workers.autoscaling_group_name
  load_balancer_target_group_arn  = module.lb.target_group_arn
  load_balancer_security_group_id = module.lb.security_group_id
  target_security_group_id        = module.cluster.security_group_id
}
