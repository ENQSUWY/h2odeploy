variable "route_zone" {
  description = "Existing Route 53 router zone that will be used for the validation record."
}

variable "domain" {
  description = "FQDN that the wildcard certificate should be created for."
}
