locals {
  postgres_name = "${var.prefix}-postgres"

  postgres_labels = {
    app       = "postgres"
    prefix    = var.prefix
    component = "postgres"
  }

  postgres_port = 5432
}


resource "kubernetes_persistent_volume_claim" "postgres_data" {
  metadata {
    namespace = var.namespace
    name      = "${local.postgres_name}-data"
    labels    = local.postgres_labels
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

resource "random_password" "postgres_admin_password" {
  length = 16
}

resource "random_password" "postgres_storage_password" {
  length = 16
}

resource "kubernetes_secret" "postgres_admin" {
  metadata {
    namespace = var.namespace
    name      = "${local.postgres_name}-admin"
  }

  data = {
    password = random_password.postgres_admin_password.result
  }
}

resource "kubernetes_secret" "postgres_storage" {
  metadata {
    namespace = var.namespace
    name      = "${local.postgres_name}-storage"
  }

  data = {
    username                = "h2oai_storage"
    password                = random_password.postgres_storage_password.result
    go_pq_connection_string = "postgres://${local.postgres_name}:${local.postgres_port}/${var.storage_db}?sslmode=disable&user=h2oai_storage&password=${urlencode(random_password.postgres_storage_password.result)}"
  }
}

resource "kubernetes_config_map" "postgres_init_scripts" {
  metadata {
    namespace = var.namespace
    name      = "${local.postgres_name}-init-scripts"
  }

  data = {
    "00-revoke-all-public.sh" = file("${path.module}/scripts/00-revoke-all-public.sh")
    "10-storage_db.sh"        = file("${path.module}/scripts/10-storage_db.sh")
  }
}


resource "kubernetes_deployment" "postgres" {
  metadata {
    namespace = var.namespace
    name      = local.postgres_name
    labels    = local.postgres_labels
  }

  spec {
    strategy {
      // Due to the volume claims, we cannot do a RollingUpdate here. As the claims would block the
      // new instance(s) from ever becoming healthy, thus blocking the update forever.
      type = "Recreate"
    }

    selector {
      match_labels = local.postgres_labels
    }

    template {
      metadata {
        labels = local.postgres_labels
      }

      spec {
        volume {
          name = "postgres-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres_data.metadata[0].name
          }
        }

        volume {
          name = "init-scripts"

          config_map {
            name = kubernetes_config_map.postgres_init_scripts.metadata[0].name
          }
        }

        container {
          name = local.postgres_name

          image             = "postgres:${var.postgres_tag}"
          image_pull_policy = "IfNotPresent"

          port {
            name           = "db"
            container_port = local.postgres_port
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_admin.metadata[0].name
                key  = "password"
              }
            }
          }

          env {
            name = "H2OAI_STORAGE_POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_storage.metadata[0].name
                key  = "password"
              }
            }
          }

          env {
            name = "H2OAI_STORAGE_POSTGRES_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_storage.metadata[0].name
                key  = "username"
              }
            }
          }

          env {
            name  = "H2OAI_STORAGE_POSTGRES_DB"
            value = var.storage_db
          }

          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql/data"
          }

          volume_mount {
            name       = "init-scripts"
            mount_path = "/docker-entrypoint-initdb.d"
          }

          liveness_probe {
            tcp_socket {
              port = local.postgres_port
            }

            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    namespace = var.namespace
    name      = local.postgres_name
  }

  spec {
    selector = local.postgres_labels

    type = var.service_type

    port {
      name = "db"
      port = local.postgres_port
    }
  }
}
