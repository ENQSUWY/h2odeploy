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

variable "studio_image" {
  description = "What docker image to use to spin up H2O.ai Studio pod."
}

variable "demo_mode" {
  description = "Whether to enable Studio's Demo Mode."
  type        = bool
}

variable "license_secret_name" {
  description = "The name of the secret resource representing the DriverlessAI license."
}

variable "deployer_deployment_name" {
  description = "The name of the deployment resource representing the H2O.ai Deployer."
}

variable "driverless_ai_credentials" {
  description = "Credentials for Driverless AI."
  type = object({
    address  = string
    username = string
    password = string
  })
}

variable "model_ops_credentials" {
  description = "Credentials for Model Ops UI."
  type = object({
    address  = string
    username = string
    password = string
  })
}

variable "user_management_credentials" {
  description = "Credentials for Keycloak."
  type = object({
    address  = string
    username = string
    password = string
  })
}

variable "q_credentials" {
  description = "Credentials for Q."
  type = object({
    address  = string
    username = string
    password = string
  })
  default = {
    address  = null
    username = null
    password = null
  }
}

variable "training_credentials" {
  description = "Credentials for Training."
  type = object({
    jupyter_address = string
    rstudio_address = string
    flow_address    = string
    username        = string
    password        = string
  })
  default = {
    jupyter_address = null
    rstudio_address = null
    flow_address    = null
    username        = null
    password        = null
  }
}
