locals {
  q_name = "${var.prefix}-q"
  q_host = "q.${var.ingress_host}"

  q_labels = {
    app       = "h2oai-q"
    prefix    = var.prefix
    component = "q"
  }

  port = 7777

  clickhouse_credential_string = "${data.kubernetes_secret.clickhouse_admin.data.username}:${urlencode(data.kubernetes_secret.clickhouse_admin.data.password)}"
  clickhouse_address           = "${var.clickhouse_service.name}:${var.clickhouse_service.http_port}"
}

data "kubernetes_secret" "clickhouse_admin" {
  metadata {
    namespace = var.namespace
    name      = var.clickhouse_admin_secret_name
  }
}

resource "random_password" "q_admin" {
  length = 16
}

resource "random_password" "q_system" {
  length = 16
}

resource "kubernetes_secret" "q_admin" {
  metadata {
    namespace = var.namespace
    name      = "${local.q_name}-admin"
  }

  data = {
    username = "admin"
    password = random_password.q_admin.result
  }

  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "q_system" {
  metadata {
    namespace = var.namespace
    name      = "${local.q_name}-system"
  }

  data = {
    username = "system"
    password = random_password.q_system.result
  }

  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "q_config" {
  metadata {
    namespace = var.namespace
    name      = "${local.q_name}-config"
  }

  data = {
    "q.toml" = templatefile("${path.module}/templates/q.toml",
      {
        listen_address     = ":${local.port}"
        external_address   = var.external_address
        internal_address   = "http://${local.q_name}:${local.port}"
        clickhouse_address = "http://${local.clickhouse_credential_string}@${local.clickhouse_address}"

        mapbox_access_token = var.mapbox_access_token

        admin_password  = kubernetes_secret.q_admin.data.password
        system_password = kubernetes_secret.q_system.data.password
      }
    )
  }
}

resource "kubernetes_persistent_volume_claim" "q_h2oq" {
  metadata {
    namespace = var.namespace
    name      = "${local.q_name}-h2oq"
    labels    = local.q_labels
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "20Gi"
      }
    }
  }

  wait_until_bound = false
}

resource "kubernetes_deployment" "q" {
  metadata {
    namespace = var.namespace
    name      = local.q_name
    labels    = local.q_labels
  }

  spec {
    strategy {
      // Due to the volume claims, we cannot do a RollingUpdate here. As the claims would block the
      // new instance(s) from ever becoming healthy, thus blocking the update forever.
      //
      // TODO(osery): Remove this once we migrate the demo deployment to Postgres SQL and S3
      // artifact storage.
      type = "Recreate"
    }

    selector {
      match_labels = local.q_labels
    }

    template {
      metadata {
        labels = local.q_labels
      }

      spec {
        volume {
          name = "configs"

          secret {
            secret_name = kubernetes_secret.q_config.metadata[0].name
          }
        }

        volume {
          name = "h2oq"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.q_h2oq.metadata[0].name
          }
        }

        container {
          name = local.q_name

          image             = var.q_image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = local.port
          }

          volume_mount {
            name       = "configs"
            mount_path = "/q.docker.toml"
            sub_path   = "q.toml"
          }

          volume_mount {
            name       = "h2oq"
            mount_path = "/h2oq"
          }

          liveness_probe {
            tcp_socket {
              port = local.port
            }

            initial_delay_seconds = 600
            period_seconds        = 30
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "q" {
  metadata {
    namespace = var.namespace
    name      = local.q_name
  }

  spec {
    selector = local.q_labels

    type = var.service_type

    port {
      name        = "http"
      port        = local.port
      target_port = local.port
      # SANDBOX ONLY node_port   = local.port
    }
  }
}

resource "kubernetes_ingress" "q" {
  metadata {
    namespace = var.namespace
    name      = local.q_name
    annotations = {
      "kubernetes.io/ingress.class" = var.kubernetes_io_ingress_class
    }
  }

  spec {
    tls {
      secret_name = "first-tls"
    }
    rule {
      host = local.q_host

      http {
        path {
          backend {
            service_name = kubernetes_service.q.metadata[0].name
            service_port = "http"
          }
        }
      }
    }
  }
}
