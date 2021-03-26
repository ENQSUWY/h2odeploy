variable "prefix" {
  description = "What prefix will be used for the resources used for the deployment."
}

variable "service_type" {
  description = "Type of the service that will be used for deployments. Should be 'NodePort' for minikube and 'ClusterIP' for EKS."
}

variable "influxdb_tag" {
  description = "What will be the tag of the docker image used to spin up InfluxDB"
  default     = "1.7.9-alpine"
}

variable "data_volume_size" {
  description = "Size of the volume used for the data in GiB."
  type        = number
}

variable "wal_volume_size" {
  description = "Size of the volume used for the Write-Ahead-Logs in GiB."
  type        = number
  default     = 10
}
