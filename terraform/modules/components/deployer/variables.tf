variable "prefix" {
  description = "What prefix will be used for the resources used for the deployment."
}

variable "service_type" {
  description = "Type of the service that will be used for deployments. Should be 'NodePort' for minikube and 'ClusterIP' for EKS."
}

variable "ingress_host" {
  description = "Base domain for the ingresses."
}

variable "deployer_image" {
  description = "What docker image to use to spin up H2O.ai Deployer pod."
}

variable "model_fetcher_image" {
  description = "What docker image to use for model fetchers."
}

variable "scorer_image" {
  description = "What docker image to use for mojo rest scorers."
}

variable "monitor_proxy_image" {
  description = "What docker image to use for scorer monitoring proxies."
}

variable "security_proxy_image" {
  description = "What docker image to use for security proxies."
}

variable "scorer_public_url" {
  description = "Public URL of scoring ingress."
}

variable "grafana_public_url" {
  description = "Public URL of Grafana server."
}

variable "grafana_internal_url" {
  description = "Internal URL of Grafana server."
}

variable "influxdb_internal_url" {
  description = "Internal URL of InfluxDB server."
}

variable "ca_secret_name" {
  description = "Name of kubernetes secret holding CA certificate."
}

variable "tls_client_secret_name" {
  description = "Names of kubernetes secret holding TLS client pair."
}

variable "tls_server_secret_name" {
  description = "Name of kubernetes secret holding TLS server pair."
}

variable "driverless_license_secret_name" {
  description = "Name of kubernetes secret holding driverless license."
}

variable "model_fetcher_tls_client_secret_name" {
  description = "Name of kubernetes secret holding Model Fetcher's TLS client pair."
}

variable "grafana_api_token" {
  description = "API token to use for authenticating with Grafana."
}

variable "storage_service" {
  description = "Storage service details."
  type = object({
    name = string
    port = number
  })
}

variable "namespace" {
  description = "Kubernetes namespace where Deployer will be installed."
}

variable "environment_namespace" {
  description = "Kubernetes namespace where Deployer will deploy models."
}
