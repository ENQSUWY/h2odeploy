variable "cluster_name" {
  description = "Name of the EKS cluster that the workers should join."
}

variable "desired_node_count" {
  description = "Initial number of worker nodes in the created autoscaling group."
  type        = number
}

variable "disk_size" {
  description = "Size of the root volume of the workers in GiB."
  type        = number
  default     = 300
}

variable "vpc_id" {
  description = "ID of the VPC that the worker nodes should be associated with."
}

variable "node_role_name" {
  description = "Name of the role to be used for the worker nodes."
}


variable "instance_type" {
  description = "Instance type that will be used for the worker node instances."
  default     = "t3a.large"
}
