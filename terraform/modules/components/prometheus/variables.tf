variable "prefix" {
  description = "What prefix will be used for the resources used for the deployment."
}

variable "service_type" {
  description = "Type of the service that will be used for deployments. Should be 'NodePort' for minikube and 'ClusterIP' for EKS."
}

variable "prometheus_server_tag" {
  description = "What will be the tag of the docker image used to spin up Prometheus server"
  default     = "v2.12.0"
}

variable "volume_size" {
  description = "Size of the volume used for the database in GiB."
  type        = number
  default     = 20
}

variable "namespace" {
  description = "Kubernetes namespace where Prometheus will be installed."
}
