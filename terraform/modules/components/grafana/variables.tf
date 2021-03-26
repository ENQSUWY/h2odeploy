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

variable "grafana_tag" {
  description = "What will be the tag of the docker image used to spin up Grafana"
  default     = "6.7.4"
}

variable "prometheus_internal_url" {
  description = "Internal URL of Prometheus server."
}

variable "influxdb_internal_url" {
  description = "Internal URL of InfluxDB server."
}

variable "volume_size" {
  description = "Size of the volume used for the data in GiB."
  type        = number
  default     = 20
}

variable "anonymous_access" {
  description = "Whether to enable anonymous access to Grafana."
  type        = bool
}
