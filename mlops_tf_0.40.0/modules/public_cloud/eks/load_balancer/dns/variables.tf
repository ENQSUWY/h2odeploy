variable "route_zone" {
  description = <<-EOD
    Existing Route 53 router zone where the the DNS records should be created.
    (e.g. "example.com.")

    This will be used as well for the validation record for the certificates.
  EOD
}

variable "domain" {
  description = "FQDN of the record to be created."
}

variable "load_balancer_arn" {
  description = "ARN of the load balancer where the created records should point to."
}
