locals {
  keycloak_name = "${var.prefix}-keycloak"
  keycloak_host = "keycloak.${var.ingress_host}"

  keycloak_labels = {
    app       = "keycloak"
    prefix    = var.prefix
    component = "keycloak"
  }

  keycloak_port = 8080
}

resource "kubernetes_persistent_volume_claim" "keycloak_data" {
  metadata {
    namespace = var.namespace
    name      = "${local.keycloak_name}-data"
    labels    = local.keycloak_labels
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

resource "kubernetes_config_map" "keycloak_env" {
  metadata {
    namespace = var.namespace
    name      = "${local.keycloak_name}-env"
  }

  data = {
    KEYCLOAK_IMPORT       = "/tmp/import/import.json"
    KEYCLOAK_LOGLEVEL     = "debug"
    PROXY_ADDRESS_FORWARDING = "true"
    KEYCLOAK_FRONTEND_URL = var.frontend_url
  }
}

resource "random_password" "keycloak_admin" {
  length = 16
}

resource "kubernetes_secret" "keycloak_admin" {
  metadata {
    namespace = var.namespace
    name      = "${local.keycloak_name}-admin"
  }

  data = {
    username = "admin"
    password = random_password.keycloak_admin.result
  }
}

resource "kubernetes_deployment" "keycloak" {
  metadata {
    namespace = var.namespace
    name      = local.keycloak_name
    labels    = local.keycloak_labels
  }

  spec {
    strategy {
      // Due to the volume claims, we cannot do a RollingUpdate here. As the claims would block the
      // new instance(s) from ever becoming healthy, thus blocking the update forever.
      type = "Recreate"
    }

    selector {
      match_labels = local.keycloak_labels
    }

    template {
      metadata {
        labels = local.keycloak_labels
      }

      spec {
        volume {
          name = "data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.keycloak_data.metadata[0].name
          }
        }

        volume {
          name = "import"
          secret {
            secret_name = kubernetes_secret.keycloak_import.metadata[0].name
            items {
              key  = "import.json"
              path = "import.json"
            }
          }
        }

        security_context {
          fs_group = 1000
        }

        container {
          name = local.keycloak_name

          image             = "jboss/keycloak:${var.keycloak_tag}"
          image_pull_policy = "IfNotPresent"

          port {
            container_port = local.keycloak_port
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.keycloak_env.metadata[0].name
            }
          }

          env {
            name = "KEYCLOAK_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.keycloak_admin.metadata[0].name
                key  = "username"
              }
            }
          }

          env {
            name = "KEYCLOAK_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.keycloak_admin.metadata[0].name
                key  = "password"
              }
            }
          }

          volume_mount {
            name       = "data"
            mount_path = "/opt/jboss/keycloak/standalone/data"
          }

          volume_mount {
            name       = "import"
            mount_path = "/tmp/import"
          }

          liveness_probe {
            http_get {
              path = "auth/realms/master"
              port = local.keycloak_port
            }

            initial_delay_seconds = 60
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "keycloak" {
  metadata {
    namespace = var.namespace
    name      = local.keycloak_name
  }

  spec {
    selector = local.keycloak_labels

    type = var.service_type

    port {
      name = "http"
      port = local.keycloak_port
      # SANDBOX ONLY node_port = local.keycloak_port
    }
  }
}

resource "kubernetes_ingress" "keycloak" {
  metadata {
    namespace = var.namespace
    name      = local.keycloak_name
    annotations = {
      "kubernetes.io/ingress.class" = var.kubernetes_io_ingress_class
    }
  }

  spec {
    tls {
      secret_name = "first-tls"
    }
    rule {
      host = local.keycloak_host

      http {
        path {
          backend {
            service_name = kubernetes_service.keycloak.metadata[0].name
            service_port = "http"
          }
        }
      }
    }
  }
}
