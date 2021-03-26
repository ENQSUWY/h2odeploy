locals {
  rabbitmq_name = "${var.prefix}-rabbitmq"

  rabbitmq_labels = {
    app       = "rabbitmq"
    prefix    = var.prefix
    component = "rabbitmq"
  }

  tcp_port  = 5672
  http_port = 15672

  drift_detection_user  = "driftuser"
  drift_detection_vhost = "drift-detection"
}

resource "random_password" "rabbitmq_driftuser" {
  length           = 16
  special          = true
  override_special = "!@$%&*()-_=+[]{}<>:?"
}

resource "kubernetes_secret" "rabbitmq_drift_env" {
  metadata {
    namespace = var.namespace
    name      = "${local.rabbitmq_name}-env"
  }

  data = {
    RABBITMQ_DEFAULT_USER  = local.drift_detection_user
    RABBITMQ_DEFAULT_PASS  = random_password.rabbitmq_driftuser.result
    RABBITMQ_DEFAULT_VHOST = local.drift_detection_vhost
  }
}

resource "kubernetes_persistent_volume_claim" "rabbitmq_data" {
  metadata {
    namespace = var.namespace
    name      = "${local.rabbitmq_name}-data"
    labels    = local.rabbitmq_labels
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "${var.volume_size}Gi"
      }
    }
  }

  wait_until_bound = false
}

resource "kubernetes_deployment" "rabbitmq" {
  metadata {
    namespace = var.namespace
    name      = local.rabbitmq_name
    labels    = local.rabbitmq_labels
  }

  spec {
    strategy {
      // Due to the volume claims, we cannot do a RollingUpdate here. As the claims would block the
      // new instance(s) from ever becoming healthy, thus blocking the update forever.
      type = "Recreate"
    }

    selector {
      match_labels = local.rabbitmq_labels
    }

    template {
      metadata {
        labels = local.rabbitmq_labels
      }

      spec {

        volume {
          name = "rabbitmq-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.rabbitmq_data.metadata[0].name
          }
        }

        container {
          name = local.rabbitmq_name

          image             = "rabbitmq:${var.rabbitmq_tag}"
          image_pull_policy = "IfNotPresent"

          env_from {
            secret_ref {
              name = kubernetes_secret.rabbitmq_drift_env.metadata[0].name
            }
          }

          port {
            name           = "tcp"
            container_port = local.tcp_port
          }

          port {
            name           = "management"
            container_port = local.http_port
          }

          volume_mount {
            name       = "rabbitmq-data"
            mount_path = "/var/lib/rabbitmq"
          }

          liveness_probe {
            tcp_socket {
              port = local.tcp_port
            }

            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "rabbitmq" {
  metadata {
    namespace = var.namespace
    name      = local.rabbitmq_name
  }

  spec {
    selector = local.rabbitmq_labels

    type = var.service_type

    port {
      name = "tcp"
      port = local.tcp_port
    }

    port {
      name = "management"
      port = local.http_port
    }
  }
}
