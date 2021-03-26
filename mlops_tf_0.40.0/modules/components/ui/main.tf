locals {
  ui_name = "${var.prefix}-ui"
  ui_host = "ui.${var.ingress_host}"

  ui_labels = {
    app       = "h2oai-storage-web"
    prefix    = var.prefix
    component = "ui"
  }

  ui_port = 9990
}

resource "kubernetes_config_map" "ui_env" {
  metadata {
    name = "${local.ui_name}-env"
  }

  data = {
    LOG_LEVEL     = "debug"
    TLS_ENABLED   = false
    COOKIE_SECURE = var.cookie_secure

    DEPLOYER_ADDRESS      = "${var.deployer_service.name}:${var.deployer_service.port}"
    DEPLOYER_TLS_ENABLED  = true
    DEPLOYER_CA_CERT_PATH = "/pki/ca/certificate"
    DEPLOYER_CERT_PATH    = "/pki/client/certificate"
    DEPLOYER_KEY_PATH     = "/pki/client/key"

    MODELINGEST_ADDRESS      = "${var.model_ingestion_service.name}:${var.model_ingestion_service.port}"
    MODELINGEST_TLS_ENABLED  = true
    MODELINGEST_CA_CERT_PATH = "/pki/ca/certificate"
    MODELINGEST_CERT_PATH    = "/pki/client/certificate"
    MODELINGEST_KEY_PATH     = "/pki/client/key"

    STORAGE_ADDRESS      = "${var.storage_service.name}:${var.storage_service.port}"
    STORAGE_TLS_ENABLED  = true
    STORAGE_CA_CERT_PATH = "/pki/ca/certificate"
    STORAGE_CERT_PATH    = "/pki/client/certificate"
    STORAGE_KEY_PATH     = "/pki/client/key"

    GRAFANA_URI     = var.grafana_internal_url
    GRAFANA_API_KEY = var.grafana_api_token

    OIDC_PROVIDER_URL            = var.oidc_identity_provider_url
    OIDC_CLIENT_ID               = var.client_id
    OIDC_TOKEN_INTROSPECTION_URL = var.oidc_introspection_url
    OIDC_REDIRECT_URL            = "${var.base_url}/oauth2/callback"
    OIDC_END_SESSION_URL         = var.oidc_end_session_url
  }
}

resource "random_password" "ui_cookie_auth_secret" {
  length = 64
}

resource "random_password" "ui_cookie_encrypt_secret" {
  length = 32
}

resource "kubernetes_secret" "ui_secrets" {
  metadata {
    name = "${local.ui_name}-secrets"
  }

  data = {
    cookie_encrypt_secret = random_password.ui_cookie_encrypt_secret.result
    cookie_auth_secret    = random_password.ui_cookie_auth_secret.result
  }
}

resource "kubernetes_deployment" "ui" {
  metadata {
    name   = local.ui_name
    labels = local.ui_labels
  }

  spec {
    selector {
      match_labels = local.ui_labels
    }

    template {
      metadata {
        labels = local.ui_labels
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
          name = local.ui_name

          image             = var.ui_image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = local.ui_port
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.ui_env.metadata[0].name
            }
          }

          env {
            name = "COOKIE_AUTH_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.ui_secrets.metadata[0].name
                key  = "cookie_auth_secret"
              }
            }
          }

          env {
            name = "COOKIE_ENCRYPT_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.ui_secrets.metadata[0].name
                key  = "cookie_encrypt_secret"
              }
            }
          }

          env {
            name = "OIDC_CLIENT_SECRET"
            value_from {
              secret_key_ref {
                name = var.client_secrets_name
                key  = "ui_client_secret"
              }
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
              path = "/version"
              port = local.ui_port
            }

            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "ui" {
  metadata {
    name = local.ui_name
  }

  spec {
    selector = local.ui_labels

    type = var.service_type

    port {
      name = "http"
      port = local.ui_port
      # SANDBOX ONLY node_port = local.ui_port
    }
  }
}

resource "kubernetes_ingress" "ui" {
  metadata {
    name = local.ui_name
    annotations = {
      "kubernetes.io/ingress.class" = var.kubernetes_io_ingress_class
    }
  }

  spec {
    rule {
      host = local.ui_host

      http {
        path {
          backend {
            service_name = kubernetes_service.ui.metadata[0].name
            service_port = "http"
          }
        }
      }
    }
  }
}
