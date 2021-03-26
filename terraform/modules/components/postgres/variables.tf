variable "prefix" {
  description = "What prefix will be used for the resources used for the deployment."
}

variable "service_type" {
  description = "Type of the service that will be used for deployments. Should be 'NodePort' for minikube and 'ClusterIP' for EKS."
}

variable "storage_db" {
  description = "Name of the database that will be used by the Storage."
}

variable "postgres_tag" {
  description = "What will be the tag of the docker image used to spin up PostgreSQL"
  default     = "11.7-alpine"
}

variable "volume_size" {
  description = "Size of the volume used for the database in GiB."
  type        = number
  default     = 20
}

variable "namespace" {
  description = "Kubernetes namespace where PostgreSQL will be installed."
}
