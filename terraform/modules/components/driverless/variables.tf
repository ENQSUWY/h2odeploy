variable "prefix" {
  description = "What prefix will be used for the resources used for the deployment."
}

variable "service_type" {
  description = "Type of the service that will be used for deployments. Should be 'NodePort' for minikube and 'ClusterIP' for EKS."
}

variable "kubernetes_io_ingress_class" {
  description = "Ingress class that hooks up services exposed to the user."
  type        = string
}

variable "ingress_host" {
  description = "Base domain for the ingresses."
}

variable "driverless_image" {
  description = "What docker image to use to spin up H2O Driverless AI pod."
}

variable "driverless_count" {
  description = "How many instances of driverless should be spinned up."
}

variable "driverless_license_path" {
  description = "Location of the Driverless AI license"
  default     = "~/.driverlessai/license.sig"
}

variable "driverless_urls" {
  description = "Expected URLs of the Driverless AI instances."
  type = object({
    urls = list(string)
  })
}

variable "oidc_identity_provider_url" {
  description = "URL of OIDC identity provider."
}

variable "oidc_introspection_url" {
  description = "URL for OIDC token introspection."
}

variable "client_id" {
  description = "ID of the OAuth2 client."
}

variable "client_secrets_name" {
  description = "Name of kubernetes secrets holding the client secrets for OAuth2 clients."
}

variable "pkce_client_id" {
  description = "ID of the OAuth2 client used for PKCE flow used for driverless clients."
}

variable "ca_secret_name" {
  description = "Name of kubernetes secret holding CA certificate."
}

variable "tls_client_secret_name" {
  description = "Names of kubernetes secret holding TLS client pair."
}

variable "storage_service" {
  description = "Storage service details."
  type = object({
    name = string
    port = number
  })
}

variable "volume_size" {
  description = "Size of the volume used for the data directory in GiB."
  type        = number
}
