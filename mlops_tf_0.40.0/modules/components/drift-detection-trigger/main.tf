locals {
  drift_detection_trigger_name = "${var.prefix}-drift-detection-trigger"

  drift_detection_trigger_labels = {
    app       = "drift-detection-trigger"
    prefix    = var.prefix
    component = "drift-detection-trigger"
  }
}

resource "kubernetes_config_map" "drift_detection_trigger_env" {
  metadata {
    name = "${local.drift_detection_trigger_name}-env"
  }

  data = {
    RMQ_HOST    = var.rabbitmq_service.host
    RMQ_PORT    = var.rabbitmq_service.port
    INFLUX_HOST = var.influx_service.host
    INFLUX_PORT = var.influx_service.port
  }
}


resource "kubernetes_cron_job" "drift_detection_trigger" {
  metadata {
    name   = local.drift_detection_trigger_name
    labels = local.drift_detection_trigger_labels
  }
  spec {
    concurrency_policy            = "Forbid"
    failed_jobs_history_limit     = 3
    schedule                      = "*/5 * * * *"
    starting_deadline_seconds     = 60
    successful_jobs_history_limit = 1
    suspend                       = false
    job_template {
      metadata {}
      spec {
        template {
          metadata {}
          spec {
            container {
              name = local.drift_detection_trigger_name

              image             = var.drift_detection_trigger_image
              image_pull_policy = "IfNotPresent"

              env_from {
                config_map_ref {
                  name = kubernetes_config_map.drift_detection_trigger_env.metadata[0].name
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
  }
}
