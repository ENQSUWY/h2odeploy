locals {
  storage_name       = "${var.prefix}-storage"
  storage_roles_name = "${local.storage_name}-roles-bootstrap"

  storage_labels = {
    app       = "h2oai-storage"
    prefix    = var.prefix
    component = "storage"
  }

  storage_port = 9999
}


resource "kubernetes_persistent_volume_claim" "storage_data" {
  metadata {
    name   = "${local.storage_name}-data"
    labels = local.storage_labels
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

resource "kubernetes_config_map" "storage_env" {
  metadata {
    name = "${local.storage_name}-env"
  }

  data = {
    LOG_LEVEL                 = "trace"
    SERVER_REFLECTION_ENABLED = true

    TLS_ENABLED      = true
    TLS_CA_CERT_PATH = "/pki/ca/certificate"
    TLS_CERT_PATH    = "/pki/server/certificate"
    TLS_KEY_PATH     = "/pki/server/key"

    DATABASE_DRIVER = var.database_driver

    # TODO(@zoido): Remove when all of the components send the version metadata.
    VERSION_CHECK_MODE = "noaction"

    OAUTH2_TOKEN_INTROSPECTION_URL = var.oidc_introspection_url
    OAUTH2_CLIENT_ID               = var.client_id

    SPIFFE_TRUST_DOMAIN      = "spiffe://${var.ingress_host}"
    SPIFFE_TRUSTED_ADMIN_IDS = "spiffe://${var.ingress_host}/deployer,spiffe://${var.ingress_host}/fetcher"
  }
}

resource "kubernetes_config_map" "bootstrap_roles_config" {
  metadata {
    name = "${local.storage_roles_name}-config"
  }

  data = {
    "roles.hcl" = file(var.roles_bootstrap_input_file)
  }
}

resource "kubernetes_config_map" "storage_roles_env" {
  metadata {
    name = "${local.storage_roles_name}-env"
  }

  data = {
    LOG_LEVEL       = "trace"
    DATABASE_DRIVER = var.database_driver
    SKIP_ON_LOCK    = true
  }
}


resource "kubernetes_deployment" "storage" {
  metadata {
    name   = local.storage_name
    labels = local.storage_labels
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
      match_labels = local.storage_labels
    }

    template {
      metadata {
        labels = local.storage_labels
      }

      spec {
        volume {
          name = "data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.storage_data.metadata[0].name
          }
        }

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
          name = "bootstrap-roles-config"

          config_map {
            name = kubernetes_config_map.bootstrap_roles_config.metadata[0].name
          }
        }


        init_container {
          name  = local.storage_roles_name
          image = var.storage_image
          args  = ["bootstrap-roles"]

          volume_mount {
            name       = "bootstrap-roles-config"
            mount_path = "/config"
          }

          env {
            name  = "INPUT_FILE"
            value = "/config/roles.hcl"
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.storage_roles_env.metadata[0].name
            }
          }

          env {
            name = "DATABASE_CONNECTION"
            value_from {
              secret_key_ref {
                name = var.database_credentials_secret_name
                key  = var.database_connection_key_name
              }
            }
          }

        }

        container {
          name = local.storage_name

          image             = var.storage_image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = local.storage_port
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.storage_env.metadata[0].name
            }
          }

          env {
            name = "OAUTH2_CLIENT_SECRET"
            value_from {
              secret_key_ref {
                name = var.client_secrets_name
                key  = "storage_client_secret"
              }
            }
          }

          env {
            name = "DATABASE_CONNECTION"
            value_from {
              secret_key_ref {
                name = var.database_credentials_secret_name
                key  = var.database_connection_key_name
              }
            }
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/opt/h2oai/storage/data"
          }

          volume_mount {
            name       = "tls-ca"
            mount_path = "/pki/ca"
          }

          volume_mount {
            name       = "tls-server"
            mount_path = "/pki/server"
          }

          liveness_probe {
            tcp_socket {
              port = local.storage_port
            }

            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "storage" {
  metadata {
    name = local.storage_name
  }

  spec {
    selector = local.storage_labels

    type = var.service_type

    port {
      port = local.storage_port
      # SANDBOX ONLY node_port = local.storage_port
    }
  }
}
