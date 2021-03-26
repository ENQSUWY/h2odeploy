variable "prefix" {
  description = "What prefix will be used for the resources used for the deployment. This will also be used as the next level subdomain"
}

variable "domain" {
  description = "Base domain for the services. This needs to be a Route53 hosted zone."
}

variable "protocol" {
  description = "Protocol for the public facing URLs of the services (http or https)."
  default     = "https"
}

variable "namespace" {
  description = "Kubernetes namespace where components will be installed. This is particularly important for DAI instances trying to reach storage, since the namespace must be specific in the hostname and mTLS certificate."
  # default     = "default"
  default     = "mlops"
  type        = string

  validation {
    condition     = contains(["default"], var.namespace)
    error_message = "Variable namespace must be the value 'default' at the present time."
  }
}

# EKS config

variable "eks_admin_arns" {
  description = "ARNs of AWS users to have admin access to the EKS cluster. This needs to be set if you want to allow acces to the server to different accounts"
  type        = list
  default     = []
}

variable "eks_admin_role_arn" {
  description = "ARN of AWS role that will have admin access to the EKS cluster."
  default     = ""
}

variable "eks_node_count" {
  description = "How many nodes will be provisioned to join the cluster."
  default     = 1
}

variable "eks_node_instance_type" {
  description = "What instance type will be the worker nodes."
  default     = "t3a.large"
}

# Component specific

variable "driverless_count" {
  description = "How many instances of driverless should be spinned up."
}

variable "driverless_license_path" {
  description = "Location of the Driverless AI license"
}

variable "storage_roles_bootstrap_input_file" {
  description = "Path to the file with configuration of the roles and permissions in the Storage."
  default     = ""
  type        = string
}

variable "grafana_anonymous_access" {
  description = "Whether to enable anonymous access to Grafana."
  type        = bool
  default     = true
}

variable "studio_access_mode" {
  description = "Choose from: production, demo"
  default     = "production"

  validation {
    condition     = contains(["production", "demo"], var.studio_access_mode)
    error_message = "Variable studio_access_mode must be production or demo."
  }
}

# Images

variable "driverless_image" {
  description = "What docker image to use to spin up H2O Driverless AI pod."
}

variable "deployer_image" {
  description = "What docker image to use for H2O.ai Deployer pod."
}

variable "drift_detection_worker_image" {
  description = "What docker image to pre-load on node for the Drift Detection worker."
}

variable "drift_detection_trigger_image" {
  description = "What docker image to pre-load on node for the Drift Detection trigger."
}

variable "storage_image" {
  description = "What docker image use for H2O.ai Storage pod."
}

variable "studio_image" {
  description = "What docker image use for H2O.ai Studio pod."
}

variable "ui_image" {
  description = "What docker image use for H2O.ai Storage UI pod."
}

variable "gateway_image" {
  description = "What docker image use for MLOps gRPC Gateway pod."
}

variable "scorer_image" {
  description = "What docker image to pre-load on node for the rest-scorer."
}

variable "monitor_proxy_image" {
  description = "What docker image to pre-load on node for the monitor proxy."
}

variable "model_fetcher_image" {
  description = "What docker image use for H2O.ai Model Fetcher init container."
}

variable "model_ingestion_image" {
  description = "What docker image use for H2O.ai Model Ingestion pod."
}

variable "security_proxy_image" {
  description = "What docker image to pre-load on node for the security proxy."
}

variable "platform_deployment_type" {
  description = "Choose from: subdomain, node_port"
  default     = "subdomain"

  validation {
    condition     = contains(["subdomain", "node_port"], var.platform_deployment_type)
    error_message = "Variable platform_deployment_type must be subdomain or node_port."
  }
}

variable "traefik_ingress_service_type" {
  description = "Choose from: ClusterIP, NodePort, LoadBalancer"
  default     = "ClusterIP"

  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.traefik_ingress_service_type)
    error_message = "Variable traefik_ingress_service_type must be ClusterIP, NodePort, or LoadBalancer."
  }
}

variable "kubernetes_io_ingress_class" {
  description = "Ingress class that hooks up services exposed to the user."
  default     = "traefik"
  type        = string
}

variable "storage_data_volume_size" {
  description = "Size of the volume used for the blob storage of the H2O.ai Storage in GiB."
  type        = number
}

variable "driverless_data_volume_size" {
  description = "Size of the volume used for the H2O Driverless AI data directory in GiB."
  type        = number
}

variable "influxdb_data_volume_size" {
  description = "Size of the volume used for the H2O Driverless AI data directory in GiB."
  type        = number
}
