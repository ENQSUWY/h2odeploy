variable "prefix" {
  description = "What prefix will be used for the resources used for the deployment."
}

variable "service_type" {
  description = "Type of the service that will be used for deployments. Should be 'NodePort' for minikube and 'ClusterIP' for EKS."
}

variable "rabbitmq_tag" {
  description = "What will be the tag of the docker image used to spin up RabbitMQ."
  default     = "3.8.3-management-alpine"
}

variable "volume_size" {
  description = "Size of the volume used for the data in GiB."
  type        = number
  default     = 20
}

variable "namespace" {
  description = "Kubernetes namespace where RabbitMQ will be installed."
}
