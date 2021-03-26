locals {
  influxdb_name = "${var.prefix}-influxdb"

  influxdb_labels = {
    app       = "influxdb"
    prefix    = var.prefix
    component = "influxdb"
  }

  http_port = 8086
  rpc_port  = 8088
}

resource "kubernetes_persistent_volume_claim" "influxdb_wal" {
  metadata {
    namespace = var.namespace
    name      = "${local.influxdb_name}-wal"
    labels    = local.influxdb_labels
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "${var.wal_volume_size}Gi"
      }
    }
  }

  wait_until_bound = false
}

resource "kubernetes_persistent_volume_claim" "influxdb_data" {
  metadata {
    namespace = var.namespace
    name      = "${local.influxdb_name}-data"
    labels    = local.influxdb_labels
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "${var.data_volume_size}Gi"
      }
    }
  }

  wait_until_bound = false
}

resource "kubernetes_config_map" "influxdb_env" {
  metadata {
    namespace = var.namespace
    name      = "${local.influxdb_name}-env"
  }

  data = {
    INFLUXDB_DATA_DIR              = "/mnt/db/data"
    INFLUXDB_DATA_WAL_DIR          = "/mnt/influx/wal"
    INFLUXDB_META_DIR              = "/mnt/db/meta"
    INFLUXDB_MONITOR_STORE_ENABLED = true
  }
}

resource "kubernetes_deployment" "influxdb" {
  metadata {
    namespace = var.namespace
    name      = local.influxdb_name
    labels    = local.influxdb_labels
  }

  spec {
    strategy {
      // Due to the volume claims, we cannot do a RollingUpdate here. As the claims would block the
      // new instance(s) from ever becoming healthy, thus blocking the update forever.
      type = "Recreate"
    }

    selector {
      match_labels = local.influxdb_labels
    }

    template {
      metadata {
        labels = local.influxdb_labels
      }

      spec {
        volume {
          name = "influxdb-wal"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.influxdb_wal.metadata[0].name
          }
        }

        volume {
          name = "influxdb-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.influxdb_data.metadata[0].name
          }
        }

        container {
          name = local.influxdb_name

          image             = "influxdb:${var.influxdb_tag}"
          image_pull_policy = "IfNotPresent"

          port {
            name           = "http"
            container_port = local.http_port
          }

          port {
            name           = "rpc"
            container_port = local.rpc_port
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.influxdb_env.metadata[0].name
            }
          }

          volume_mount {
            name       = "influxdb-wal"
            mount_path = "/mnt/influx"
          }

          volume_mount {
            name       = "influxdb-data"
            mount_path = "/mnt/db"
          }

          liveness_probe {
            http_get {
              path = "/ping"
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

resource "kubernetes_service" "influxdb" {
  metadata {
    namespace = var.namespace
    name      = local.influxdb_name
  }

  spec {
    selector = local.influxdb_labels

    type = var.service_type

    port {
      name = "http"
      port = local.http_port
    }

    port {
      name = "rpc"
      port = local.rpc_port
    }
  }
}
