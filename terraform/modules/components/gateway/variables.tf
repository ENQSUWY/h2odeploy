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

variable "gateway_image" {
  description = "What docker image use for MLOps gRPC Gateway pod."
}

variable "ca_secret_name" {
  description = "Name of kubernetes secret holding CA certificate."
}

variable "tls_client_secret_name" {
  description = "Names of kubernetes secret holding TLS client pair."
}

variable "storage_service" {
  description = "Storage service details."
  type = object({
    name = string
    port = number
  })
}

variable "deployer_service" {
  description = "Deployer service details."
  type = object({
    name = string
    port = number
  })
}

variable "model_ingestion_service" {
  description = "Model ingestion service details."
  type = object({
    name = string
    port = number
  })
}

variable "namespace" {
  description = "Kubernetes namespace where gRPC Gateway will be installed."
}
