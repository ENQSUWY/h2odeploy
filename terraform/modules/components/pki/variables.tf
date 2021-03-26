variable "prefix" {
  description = "What prefix will be used for the resources used for the deployment."
}

variable "components_namespace" {
  description = "Kubernetes namespace where components will be installed. This is particularly important for DAI instances trying to reach storage, since the namespace must be specific in the hostname and mTLS certificate."
}

variable "spiffe_trust_domain" {
  description = "Trust domain for SPIFFE authenticcation."
}

variable "tls_validity_period_hours" {
  description = "How long will the provisioned certificates stay valid."
  default     = 87600
}

variable "tls_servers" {
  description = "List of TLS servers to generate certificates for."
  type        = list(string)
}

variable "tls_clients" {
  description = "List of TLS clients to generate certificates for."
  type = map(object({
    // Whether SPIFFE information should be included in the certificate.
    spiffe : bool,
  }))
}

variable "namespace" {
  description = "Kubernetes namespace where certificates will be installed."
}
