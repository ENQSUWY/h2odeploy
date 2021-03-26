locals {
  prometheus_server_name = "${var.prefix}-prometheus-server"

  prometheus_server_labels = {
    app       = "prometheus"
    prefix    = var.prefix
    component = "prometheus_server"
  }

  prometheus_server_port          = 9100
  prometheus_server_data_dir_path = "/prometheus"
}

resource "kubernetes_persistent_volume_claim" "prometheus_server_data" {
  metadata {
    name   = "${local.prometheus_server_name}-data"
    labels = local.prometheus_server_labels
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

resource "kubernetes_config_map" "prometheus_server_config" {
  metadata {
    name = "${local.prometheus_server_name}-config"
  }

  data = {
    "prometheus.yaml" = templatefile("${path.module}/templates/prometheus.yaml",
      {
        scrape_interval = "5s"
      }
    )
  }
}

resource "kubernetes_deployment" "prometheus_server" {
  metadata {
    name   = local.prometheus_server_name
    labels = local.prometheus_server_labels
  }

  spec {
    strategy {
      // Due to the volume claims, we cannot do a RollingUpdate here. As the claims would block the
      // new instance(s) from ever becoming healthy, thus blocking the update forever.
      type = "Recreate"
    }

    selector {
      match_labels = local.prometheus_server_labels
    }

    template {
      metadata {
        labels = local.prometheus_server_labels
      }

      spec {
        volume {
          name = "data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.prometheus_server_data.metadata[0].name
          }
        }

        volume {
          name = "config"

          config_map {
            name = kubernetes_config_map.prometheus_server_config.metadata[0].name
            items {
              key  = "prometheus.yaml"
              path = "prometheus.yaml"
            }
          }
        }

        security_context {
          fs_group = 0
        }

        container {
          name = local.prometheus_server_name

          image             = "prom/prometheus:${var.prometheus_server_tag}"
          image_pull_policy = "IfNotPresent"

          port {
            container_port = local.prometheus_server_port
          }

          volume_mount {
            name       = "data"
            mount_path = local.prometheus_server_data_dir_path
          }

          volume_mount {
            name       = "config"
            mount_path = "/config"
          }

          args = [
            "--config.file=/config/prometheus.yaml",
            "--storage.tsdb.path=${local.prometheus_server_data_dir_path}",
            "--log.level=debug",
            "--storage.tsdb.no-lockfile",
            "--web.listen-address=:${local.prometheus_server_port}",
          ]

          liveness_probe {
            http_get {
              path = "/-/healthy"
              port = local.prometheus_server_port
            }

            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "prometheus_server" {
  metadata {
    name = local.prometheus_server_name
  }

  spec {
    selector = local.prometheus_server_labels

    type = var.service_type

    port {
      port = local.prometheus_server_port
    }
  }
}
