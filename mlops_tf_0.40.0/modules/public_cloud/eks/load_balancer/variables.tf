variable "route_zone" {
  description = <<EOD
    Existing Route 53 router zone where the the DNS records should be created.
    (e.g. "example.com.")

    This will be used as well for the validation record for the certificates.
  EOD
}

variable "domain" {
  description = "FQDN of the record to be created."
}

variable "name" {
  description = "Name of the all associated resources to be created."
}

variable "vpc_id" {
  description = "ID of the VPC that should be used for the created resources."
}

variable "target_port" {
  description = "Port where the load balancer will forward the traffic."
  type        = number
}
