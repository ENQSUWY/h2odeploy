variable "prefix" {
  description = "What prefix will be used for the resources used for the deployment."
}

variable "drift_detection_trigger_image" {
  description = "What docker image to use to spin up H2O.ai Storage pod."
}

variable "rabbitmq_service" {
  description = "Internal RabbitMQ service"
}

variable "influx_service" {
  description = "Internal Influx service"
}

variable "rabbitmq_drift_secrets" {
  description = "Kubernetes secret name for Drift Detection specific secrets"
}

variable "namespace" {
  description = "Kubernetes namespace where Drift detection Trigger will be installed."
}
