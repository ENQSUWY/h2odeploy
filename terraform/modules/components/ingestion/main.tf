locals {
  ingestion_name = "${var.prefix}-ingestion"

  ingestion_labels = {
    app       = "h2oai-ingestion"
    prefix    = var.prefix
    component = "ingestion"
  }
  ingestion_port = 9911
}

resource "kubernetes_config_map" "ingestion_env" {
  metadata {
    name = "${local.ingestion_name}-env"
  }

  data = {
    LOG_LEVEL         = "trace"
    BIND              = ":${local.ingestion_port}"
    SERVER_REFLECTION = true

    SERVER_TLS         = true
    SERVER_TLS_CA_CERT = "/pki/ca/certificate"
    SERVER_TLS_CERT    = "/pki/server/certificate"
    SERVER_TLS_KEY     = "/pki/server/key"

    STORAGE_ADDRESS     = "${var.storage_service.name}:${var.storage_service.port}"
    STORAGE_TLS         = true
    STORAGE_TLS_CA_CERT = "/pki/ca/certificate"
    STORAGE_TLS_CERT    = "/pki/client/certificate"
    STORAGE_TLS_KEY     = "/pki/client/key"
  }
}


resource "kubernetes_deployment" "ingestion" {
  metadata {
    name   = local.ingestion_name
    labels = local.ingestion_labels
  }

  spec {
    strategy {
      // Due to the volume claims, we cannot do a RollingUpdate here. As the claims would block the
      // new instance(s) from ever becoming healthy, thus blocking the update forever.
      type = "Recreate"
    }

    selector {
      match_labels = local.ingestion_labels
    }

    template {
      metadata {
        labels = local.ingestion_labels
      }

      spec {
        volume {
          name = "tls-ca"

          secret {
            secret_name = var.ca_secret_name
          }
        }

        volume {
          name = "tls-server"

          secret {
            secret_name = var.tls_server_secret_name
          }
        }

        volume {
          name = "tls-client"

          secret {
            secret_name = var.tls_client_secret_name
          }
        }

        container {
          name = local.ingestion_name

          image             = var.model_ingestion_image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = local.ingestion_port
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.ingestion_env.metadata[0].name
            }
          }

          volume_mount {
            name       = "tls-ca"
            mount_path = "/pki/ca"
          }

          volume_mount {
            name       = "tls-server"
            mount_path = "/pki/server"
          }

          volume_mount {
            name       = "tls-client"
            mount_path = "/pki/client"
          }

          liveness_probe {
            tcp_socket {
              port = local.ingestion_port
            }

            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "ingestion" {
  metadata {
    name = local.ingestion_name
  }

  spec {
    selector = local.ingestion_labels

    type = var.service_type

    port {
      port        = local.ingestion_port
      target_port = local.ingestion_port
      # SANDBOX ONLY node_port = local.ingestion_port
    }
  }
}
