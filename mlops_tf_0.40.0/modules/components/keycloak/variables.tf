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

variable "keycloak_tag" {
  description = "What will be the tag of the docker image used to spin up keycloak"
  default     = "8.0.1"
}

variable "frontend_url" {
  description = "Expected frontend URL for accessing Keycloak."
}

variable "oauth2_redirect_urls" {
  description = "OAuth2 client public allowed redirect urls for individual components."
  type = object({
    driverless = list(string)
    ui         = list(string)
  })
}

variable "volume_size" {
  description = "Size of the volume used for the database in GiB."
  type        = number
  default     = 5
}
