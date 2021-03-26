locals {
  drift_detection_worker_name = "${var.prefix}-drift-detection-worker"

  drift_detection_worker_labels = {
    app       = "drift-detection-worker"
    prefix    = var.prefix
    component = "drift-detection-worker"
  }
}

resource "kubernetes_config_map" "drift_detection_worker_env" {
  metadata {
    name = "${local.drift_detection_worker_name}-env"
  }

  data = {
    RMQ_HOST    = var.rabbitmq_service.host
    RMQ_PORT    = var.rabbitmq_service.port
    INFLUX_HOST = var.influx_service.host
    INFLUX_PORT = var.influx_service.port
  }
}

resource "kubernetes_deployment" "drift_detection_worker" {
  metadata {
    name   = local.drift_detection_worker_name
    labels = local.drift_detection_worker_labels
  }

  spec {
    strategy {
      // Due to the volume claims, we cannot do a RollingUpdate here. As the claims would block the
      // new instance(s) from ever becoming healthy, thus blocking the update forever.
      type = "Recreate"
    }

    selector {
      match_labels = local.drift_detection_worker_labels
    }

    template {
      metadata {
        labels = local.drift_detection_worker_labels
      }

      spec {
        container {
          name              = local.drift_detection_worker_name
          image             = var.drift_detection_worker_image
          image_pull_policy = "IfNotPresent"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.drift_detection_worker_env.metadata[0].name
            }
          }

          env {
            name = "RMQ_DRIFT_USER"
            value_from {
              secret_key_ref {
                name = var.rabbitmq_drift_secrets
                key  = "RABBITMQ_DEFAULT_USER"
              }
            }
          }

          env {
            name = "RMQ_DRIFT_PASSWORD"
            value_from {
              secret_key_ref {
                name = var.rabbitmq_drift_secrets
                key  = "RABBITMQ_DEFAULT_PASS"
              }
            }
          }

          env {
            name = "RMQ_DRIFT_VHOST"
            value_from {
              secret_key_ref {
                name = var.rabbitmq_drift_secrets
                key  = "RABBITMQ_DEFAULT_VHOST"
              }
            }
          }
        }
      }
    }
  }
}
