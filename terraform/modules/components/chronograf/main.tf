locals {
  chronograf_name = "${var.prefix}-chronograf"

  chronograf_labels = {
    app       = "chronograf"
    prefix    = var.prefix
    component = "chronograf"
  }

  chronograf_port = 8888
}

resource "kubernetes_persistent_volume_claim" "chronograf_data" {
  metadata {
    namespace = var.namespace
    name      = "${local.chronograf_name}-data"
    labels    = local.chronograf_labels
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }

  wait_until_bound = false
}

resource "kubernetes_config_map" "chronograf_env" {
  metadata {
    namespace = var.namespace
    name      = "${local.chronograf_name}-env"
  }

  data = {
    INFLUXDB_URL = var.influxdb_internal_url
    HOST         = "0.0.0.0"
    PORT         = local.chronograf_port
    LOG_LEVEL    = "debug"
  }
}

resource "kubernetes_deployment" "chronograf" {
  metadata {
    namespace = var.namespace
    name      = local.chronograf_name
    labels    = local.chronograf_labels
  }

  spec {
    strategy {
      // Due to the volume claims, we cannot do a RollingUpdate here. As the claims would block the
      // new instance(s) from ever becoming healthy, thus blocking the update forever.
      type = "Recreate"
    }

    selector {
      match_labels = local.chronograf_labels
    }

    template {
      metadata {
        labels = local.chronograf_labels
      }

      spec {
        volume {
          name = "chronograf-data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.chronograf_data.metadata[0].name
          }
        }

        container {
          name = local.chronograf_name

          image             = "chronograf:${var.chronograf_tag}"
          image_pull_policy = "IfNotPresent"

          port {
            name           = "ui"
            container_port = local.chronograf_port
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.chronograf_env.metadata[0].name
            }
          }

          volume_mount {
            name       = "chronograf-data"
            mount_path = "/var/lib/chronograf"
          }

          liveness_probe {
            http_get {
              path = "/ping"
              port = local.chronograf_port
            }

            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "chronograf" {
  metadata {
    namespace = var.namespace
    name      = local.chronograf_name
  }

  spec {
    selector = local.chronograf_labels

    type = var.service_type

    port {
      name = "ui"
      port = local.chronograf_port
    }
  }
}
