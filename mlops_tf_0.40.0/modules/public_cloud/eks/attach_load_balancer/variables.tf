variable "autoscaling_group_name" {
  description = "Name of the autoscaling group load balancer should attach to."
}
variable "load_balancer_target_group_arn" {
  description = "ARN of the load balancer target group that should be attached."
}

variable "target_security_group_id" {
  description = "ID of the security group of the target that will be used to allow the traffic from the load balancer."
}

variable "load_balancer_security_group_id" {
  description = "ID of the security group associated with the load balancer that should be attached."
}

variable "port" {
  description = "Target port where the traffic should be allowed."
  type        = number
}
