variable "prefix" {
  description = "What prefix will be used for the resources used for the deployment."
}

variable "service_type" {
  description = "Type of the service that will be used for deployments. Should be 'NodePort' for minikube and 'ClusterIP' for EKS."
}

variable "clickhouse_tag" {
  description = "What will be the tag of the docker image used to spin up ClickHouse."
  default     = "20.1.9.54"
}

variable "ca_secret_name" {
  description = "Name of kubernetes secret holding CA certificate."
}

variable "tls_server_secret_name" {
  description = "Name of kubernetes secret holding TLS server pair."
}

variable "volume_size" {
  description = "Size of the volume used for the data in GiB."
  type        = number
}
