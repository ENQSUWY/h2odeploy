locals {
  clickhouse_name = "${var.prefix}-clickhouse"

  clickhouse_labels = {
    app       = "clickhouse"
    prefix    = var.prefix
    component = "clickhouse"
  }

  http_port  = 8123
  https_port = 8443

  tcp_port        = 9000
  tcp_port_secure = 9440
}

resource "random_password" "clickhouse_admin" {
  length = 16
}

resource "kubernetes_secret" "clickhouse_admin" {
  metadata {
    namespace = var.namespace
    name      = "${local.clickhouse_name}-admin"
  }

  data = {
    username = "default"
    password = random_password.clickhouse_admin.result
  }

  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_config_map" "clickhouse_config" {
  metadata {
    namespace = var.namespace
    name      = "${local.clickhouse_name}-config"
  }

  data = {
    "default.xml" = templatefile("${path.module}/templates/default.xml",
      {
        default_password_sha256 = sha256(random_password.clickhouse_admin.result)
      }
    )

    "tls.xml" = templatefile("${path.module}/templates/tls.xml",
      {
        https_port      = local.https_port
        tcp_port_secure = local.tcp_port_secure
      }
    )
  }
}

resource "kubernetes_persistent_volume_claim" "clickhouse_data" {
  metadata {
    namespace = var.namespace
    name      = "${local.clickhouse_name}-data"
    labels    = local.clickhouse_labels
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

// TODO(orendain): Set ClickHouse container nofile ulimit to 262144.
resource "kubernetes_deployment" "clickhouse" {
  metadata {
    namespace = var.namespace
    name      = local.clickhouse_name
    labels    = local.clickhouse_labels
  }

  spec {
    strategy {
      // Due to the volume claims, we cannot do a RollingUpdate here. As the claims would block the
      // new instance(s) from ever becoming healthy, thus blocking the update forever.
      type = "Recreate"
    }

    selector {
      match_labels = local.clickhouse_labels
    }

    template {
      metadata {
        labels = local.clickhouse_labels
      }

      spec {
        volume {
          name = "config"

          config_map {
            name = kubernetes_config_map.clickhouse_config.metadata[0].name
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
          name = "clickhouse-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.clickhouse_data.metadata[0].name
          }
        }

        container {
          name = local.clickhouse_name

          image             = "yandex/clickhouse-server:${var.clickhouse_tag}"
          image_pull_policy = "IfNotPresent"

          port {
            name           = "http"
            container_port = local.http_port
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/clickhouse-server/users.d/default.xml"
            sub_path   = "default.xml"
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/clickhouse-server/config.d/tls.xml"
            sub_path   = "tls.xml"
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
            name       = "clickhouse-data"
            mount_path = "/var/lib/clickhouse"
          }

          liveness_probe {
            http_get {
              path = "/"
              port = local.http_port
            }

            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "clickhouse" {
  metadata {
    namespace = var.namespace
    name      = local.clickhouse_name
  }

  spec {
    selector = local.clickhouse_labels

    type = var.service_type

    port {
      name = "http"
      port = local.http_port
    }
  }
}
