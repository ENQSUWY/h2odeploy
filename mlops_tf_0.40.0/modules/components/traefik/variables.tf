variable "prefix" {
  description = "What prefix will be used for the resources used for the deployment."
}

variable "traefik_tag" {
  description = "What will be the tag of the docker image used to spin up Traefik"
  default     = "v1.7.14"
}

variable "traefik_ingress_service_type" {
  description = "Choose from: ClusterIP, NodePort, LoadBalancer"
}
