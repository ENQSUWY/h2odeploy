locals {
  studio_name = "${var.prefix}-studio"
  studio_host = "studio.${var.ingress_host}"

  studio_labels = {
    app       = "h2oai-platform-studio"
    prefix    = var.prefix
    component = "studio"
  }

  port = 80
}

resource "kubernetes_secret" "studio_env" {
  metadata {
    namespace = var.namespace
    name      = "${local.studio_name}-env"
  }

  data = {
    DEMO_MODE_ENABLED        = var.demo_mode
    LICENSE_SECRET_NAME      = var.license_secret_name
    DEPLOYER_DEPLOYMENT_NAME = var.deployer_deployment_name

    DRIVERLESS_AI_ADDRESS  = var.driverless_ai_credentials.address
    DRIVERLESS_AI_USERNAME = var.driverless_ai_credentials.username
    DRIVERLESS_AI_PASSWORD = var.driverless_ai_credentials.password

    MODEL_OPS_ADDRESS  = var.model_ops_credentials.address
    MODEL_OPS_USERNAME = var.model_ops_credentials.username
    MODEL_OPS_PASSWORD = var.model_ops_credentials.password

    USER_MANAGEMENT_ADDRESS  = var.user_management_credentials.address
    USER_MANAGEMENT_USERNAME = var.user_management_credentials.username
    USER_MANAGEMENT_PASSWORD = var.user_management_credentials.password

    Q_ADDRESS  = var.q_credentials.address
    Q_USERNAME = var.q_credentials.username
    Q_PASSWORD = var.q_credentials.password

    TRAINING_JUPYTER_ADDRESS = var.training_credentials.jupyter_address
    TRAINING_RSTUDIO_ADDRESS = var.training_credentials.rstudio_address
    TRAINING_FLOW_ADDRESS    = var.training_credentials.flow_address
    TRAINING_USERNAME        = var.training_credentials.username
    TRAINING_PASSWORD        = var.training_credentials.password
  }
}

resource "kubernetes_deployment" "studio" {
  metadata {
    namespace = var.namespace
    name      = local.studio_name
    labels    = local.studio_labels
  }

  spec {
    selector {
      match_labels = local.studio_labels
    }

    template {
      metadata {
        labels = local.studio_labels
      }

      spec {
        service_account_name            = kubernetes_service_account.studio.metadata[0].name
        automount_service_account_token = true

        container {
          name = local.studio_name

          image             = var.studio_image
          image_pull_policy = "IfNotPresent"

          env_from {
            secret_ref {
              name = kubernetes_secret.studio_env.metadata[0].name
            }
          }

          port {
            container_port = local.port
          }

          liveness_probe {
            http_get {
              path = "/"
              port = local.port
            }

            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "studio" {
  metadata {
    namespace = var.namespace
    name      = local.studio_name
  }

  spec {
    selector = local.studio_labels

    type = var.service_type

    port {
      name = "http"
      port = local.port
      # SANDBOX ONLY node_port = local.port
    }
  }
}

resource "kubernetes_ingress" "studio" {
  metadata {
    namespace = var.namespace
    name      = local.studio_name
    annotations = {
      "kubernetes.io/ingress.class" = var.kubernetes_io_ingress_class
    }
  }

  spec {
    rule {
      host = local.studio_host

      http {
        path {
          backend {
            service_name = kubernetes_service.studio.metadata[0].name
            service_port = "http"
          }
        }
      }
    }
    tls {
      secret_name = "first-tls"
      }
  }
}
