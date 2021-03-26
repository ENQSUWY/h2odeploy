locals {
  gateway_name = "${var.prefix}-gateway"
  gateway_host = "api.${var.ingress_host}"

  gateway_labels = {
    app       = "h2oai-mlops-gateway"
    prefix    = var.prefix
    component = "gateway"
  }

  gateway_port = 9500
}

resource "kubernetes_config_map" "gateway_env" {
  metadata {
    name = "${local.gateway_name}-env"
  }

  data = {
    LOG_LEVEL   = "debug"
    TLS_ENABLED = false

    DEPLOYER_ADDRESS     = "${var.deployer_service.name}:${var.deployer_service.port}"
    DEPLOYER_TLS_ENABLED = true
    DEPLOYER_TLS_CA_CERT = "/pki/ca/certificate"
    DEPLOYER_TLS_CERT    = "/pki/client/certificate"
    DEPLOYER_TLS_KEY     = "/pki/client/key"

    MODELINGEST_ADDRESS     = "${var.model_ingestion_service.name}:${var.model_ingestion_service.port}"
    MODELINGEST_TLS_ENABLED = true
    MODELINGEST_TLS_CA_CERT = "/pki/ca/certificate"
    MODELINGEST_TLS_CERT    = "/pki/client/certificate"
    MODELINGEST_TLS_KEY     = "/pki/client/key"

    STORAGE_ADDRESS     = "${var.storage_service.name}:${var.storage_service.port}"
    STORAGE_TLS_ENABLED = true
    STORAGE_TLS_CA_CERT = "/pki/ca/certificate"
    STORAGE_TLS_CERT    = "/pki/client/certificate"
    STORAGE_TLS_KEY     = "/pki/client/key"
  }
}


resource "kubernetes_deployment" "gateway" {
  metadata {
    name   = local.gateway_name
    labels = local.gateway_labels
  }

  spec {
    selector {
      match_labels = local.gateway_labels
    }

    template {
      metadata {
        labels = local.gateway_labels
      }


      spec {
        volume {
          name = "tls-ca"

          secret {
            secret_name = var.ca_secret_name
          }
        }

        volume {
          name = "tls-client"

          secret {
            secret_name = var.tls_client_secret_name
          }
        }

        container {
          name = local.gateway_name

          image             = var.gateway_image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = local.gateway_port
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.gateway_env.metadata[0].name
            }
          }

          volume_mount {
            name       = "tls-ca"
            mount_path = "/pki/ca"
          }

          volume_mount {
            name       = "tls-client"
            mount_path = "/pki/client"
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = local.gateway_port
            }

            initial_delay_seconds = 60
            period_seconds        = 30
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "gateway" {
  metadata {
    name = local.gateway_name
  }

  spec {
    selector = local.gateway_labels

    type = var.service_type

    port {
      name = "http"
      port = local.gateway_port
      # SANDBOX ONLY node_port = local.gateway_port
    }
  }
}

resource "kubernetes_ingress" "gateway" {
  metadata {
    name = local.gateway_name
    annotations = {
      "kubernetes.io/ingress.class" = "traefik"
    }
  }

  spec {
    rule {
      host = local.gateway_host

      http {
        path {
          backend {
            service_name = kubernetes_service.gateway.metadata[0].name
            service_port = "http"
          }
        }
      }
    }
  }
}
