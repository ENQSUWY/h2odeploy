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

variable "ambassador_tag" {
  description = "What will be the tag of the docker image used to spin up Ambassador proxy"
  default     = "0.77.0"
}

variable "ui_public_url" {
  description = "Public URL of MM UI for setting up deployed scorers' CORS for MM UI introspection."
}

variable "namespace" {
  description = "Kubernetes namespace where Ambassador will be installed."
}
