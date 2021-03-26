variable "name" {
  description = "Name of the EKS cluster to be created."
}

variable "vpc_id" {
  description = "ID of the VPC that the EKS cluster should be created in."
}

variable "cluster_role_name" {
  description = "Name of the role to be used for the EKS."
}
