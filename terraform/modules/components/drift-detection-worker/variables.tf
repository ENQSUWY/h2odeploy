variable "prefix" {
  description = "What prefix will be used for the resources used for the deployment."
}

variable "drift_detection_worker_image" {
  description = "What docker image to use to spin up H2O.ai Storage pod."
}

variable "rabbitmq_service" {
  description = "Internal service for RabbitMQ"
}

variable "influx_service" {
  description = "Internal service for InfluxDB"
}

variable "rabbitmq_drift_secrets" {
  description = "Kubernetes secret name for Drift Detection specific secrets"
}

variable "namespace" {
  description = "Kubernetes namespace where Drift detection worker will be installed."
}
