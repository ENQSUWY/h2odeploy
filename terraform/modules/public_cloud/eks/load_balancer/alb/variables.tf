variable "name" {
  description = "Name of the load balancer and all of the associated resources to be created."
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate to be used with the load balancer."
}

variable "vpc_id" {
  description = "ID of the VPC that should be used for the created resources."
}

variable "target_port" {
  description = "Port where the load balancer will forward the traffic."
  type        = number
}
