variable "prefix" {
  description = "What prefix will be used for the resources used for the deployment."
}

variable "service_type" {
  description = "Type of the service that will be used for deployments. Should be 'NodePort' for minikube and 'ClusterIP' for EKS."
}

variable "chronograf_tag" {
  description = "What will be the tag of the docker image used to spin up Chronograf"
  default     = "1.7.16-alpine"
}

variable "influxdb_internal_url" {
  description = "Internal URL of InfluxDB server."
}

variable "namespace" {
  description = "Kubernetes namespace where Chronograph will be installed."
}
