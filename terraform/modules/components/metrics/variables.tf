variable "metrics_tag" {
  description = "What will be the tag of the docker image used to spin up Metrics Server"
  default     = "v0.3.5"
}

variable "namespace" {
  description = "Kubernetes namespace where Keycloak will be installed."
}
