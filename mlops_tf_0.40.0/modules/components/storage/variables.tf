variable "prefix" {
  description = "What prefix will be used for the resources used for the deployment."
}

variable "service_type" {
  description = "Type of the service that will be used for deployments. Should be 'NodePort' for minikube and 'ClusterIP' for EKS."
}

variable "ingress_host" {
  description = "Base domain for the ingresses."
}

variable "storage_image" {
  description = "What docker image to use to spin up H2O.ai Storage pod."
}

variable "oidc_introspection_url" {
  description = "URL for OIDC token introspection."
}

variable "client_id" {
  description = "OAuth2 client ID Storage."
}

variable "client_secrets_name" {
  description = "Name of kubernetes secrets holding the client secret for OAuth2 clients."
}

variable "ca_secret_name" {
  description = "Name of kubernetes secret holding CA certificate."
}

variable "tls_server_secret_name" {
  description = "Name of kubernetes secret holding TLS server pair."
}

variable "database_connection_key_name" {
  description = "Key of the `storage_database_credentials_secret_name` that holds the database connection_string"
}

variable "database_driver" {
  description = "Which database driver will Storage use."
}

variable "database_credentials_secret_name" {
  description = "Name of kubernetes secrets holding the credentials for DB."
}

variable "roles_bootstrap_input_file" {
  description = "Path to the file with configuration of the roles and permissions."
}

variable "volume_size" {
  description = "Size of the volume used for the data directory in GiB."
  type        = number
}
