variable "prefix" {
  description = "What prefix will be used for the resources used for the deployment."
}

variable "service_type" {
  description = "Type of the service that will be used for deployments. Should be 'NodePort' for minikube and 'ClusterIP' for EKS."
}

variable "model_ingestion_image" {
  description = "What docker image to use to spin up H2O.ai Ingestion pod."
}

variable "ca_secret_name" {
  description = "Name of kubernetes secret holding CA certificate."
}

variable "tls_client_secret_name" {
  description = "Name of kubernetes secret holding TLS client pair."
}

variable "tls_server_secret_name" {
  description = "Name of kubernetes secret holding TLS server pair."
}

variable "storage_service" {
  description = "Description of the Storage service"
}

variable "namespace" {
  description = "Kubernetes namespace where Model Ingestion will be installed."
}
