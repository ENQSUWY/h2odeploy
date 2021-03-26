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

variable "ui_image" {
  description = "What docker image to use to spin up H2O.ai Storage UI pod."
}

variable "grafana_internal_url" {
  description = "Internal URL of Grafna server."
}

variable "oidc_identity_provider_url" {
  description = "URL of OIDC identity provider."
}

variable "base_url" {
  description = "Expected base URL for the UI."
}

variable "oidc_introspection_url" {
  description = "URL for OIDC token introspection."
}

variable "oidc_end_session_url" {
  description = "URL for OIDC end session endpoint."
}

variable "client_id" {
  description = "ID of the OAuth2 client."
}

variable "client_secrets_name" {
  description = "Name of kubernetes secrets holding the client secrets for OAuth2 clients."
}

variable "ca_secret_name" {
  description = "Name of kubernetes secret holding CA certificate."
}

variable "tls_client_secret_name" {
  description = "Names of kubernetes secret holding TLS client pair."
}

variable "cookie_secure" {
  description = "Whether to flag cookies as 'Secure'."
  type        = bool
}

variable "grafana_api_token" {
  description = "API token to use for authenticating with Grafana."
}

variable "storage_service" {
  description = "Storage service details."
  type = object({
    name = string
    port = number
  })
}

variable "deployer_service" {
  description = "Deployer service details."
  type = object({
    name = string
    port = number
  })
}

variable "model_ingestion_service" {
  description = "Model ingestion service details."
  type = object({
    name = string
    port = number
  })
}
