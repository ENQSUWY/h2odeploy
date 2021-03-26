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

variable "q_image" {
  description = "What docker image to use to spin up Q pod."
}

variable "external_address" {
  description = "The external address for accessing Q."
}

variable "clickhouse_service" {
  description = "ClickHouse service details."
  type = object({
    name      = string
    http_port = number
  })
}

variable "clickhouse_admin_secret_name" {
  description = "Name of Kubernetes secret holding ClickHouse admin credentials."
}

variable "mapbox_access_token" {
  description = "Access token with which to authorize with Mapbox."
}

variable "namespace" {
  description = "Kubernetes namespace where Q will be installed."
}
