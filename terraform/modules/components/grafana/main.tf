locals {
  grafana_name = "${var.prefix}-grafana"
  grafana_host = "grafana.${var.ingress_host}"

  grafana_labels = {
    app       = "grafana"
    prefix    = var.prefix
    component = "grafana"
  }

  grafana_port = 3000
}

resource "kubernetes_persistent_volume_claim" "grafana_data" {
  metadata {
    name   = "${local.grafana_name}-data"
    labels = local.grafana_labels
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

resource "kubernetes_config_map" "grafana_datasources" {
  metadata {
    name = "${local.grafana_name}-config"
  }

  data = {
    "prometheus.yaml" = templatefile("${path.module}/templates/grafana_prometheus_datasource.yaml",
      { prometheus_url = var.prometheus_internal_url }
    )
    "influxdb.yaml" = templatefile("${path.module}/templates/grafana_influxdb_datasource.yaml",
      { influxdb_url = var.influxdb_internal_url }
    )
  }
}

resource "kubernetes_config_map" "grafana_env" {
  metadata {
    name = "${local.grafana_name}-env"
  }

  data = {
    GF_DEFAULT_INSTANCE_NAME = "Grafana ${var.prefix}"
    GF_SERVER_HTTP_PORT      = local.grafana_port

    GF_AUTH_BASIC_ENABLED        = true
    GF_AUTH_DISABLE_LOGIN_FORM   = false
    GF_AUTH_DISABLE_SIGNOUT_MENU = false
    GF_AUTH_ANONYMOUS_ENABLED    = var.anonymous_access
    GF_AUTH_ANONYMOUS_ORG_ROLE   = "Viewer"

    GF_PATHS_PROVISIONING = "/provisioning"
    GF_PATHS_DATA         = "/data"
  }
}

resource "random_password" "grafana_admin" {
  length = 16
}

resource "kubernetes_secret" "grafana_admin" {
  metadata {
    name = "${local.grafana_name}-admin"
  }

  data = {
    username = "admin"
    password = random_password.grafana_admin.result
  }
}

resource "kubernetes_deployment" "grafana" {
  metadata {
    name   = local.grafana_name
    labels = local.grafana_labels
  }

  spec {
    strategy {
      // Due to the volume claims, we cannot do a RollingUpdate here. As the claims would block the
      // new instance(s) from ever becoming healthy, thus blocking the update forever.
      type = "Recreate"
    }

    selector {
      match_labels = local.grafana_labels
    }

    template {
      metadata {
        labels = local.grafana_labels
      }

      spec {
        volume {
          name = "datasources-provisioning"

          config_map {
            name = kubernetes_config_map.grafana_datasources.metadata[0].name
          }
        }
        volume {
          name = "data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.grafana_data.metadata[0].name
          }
        }

        security_context {
          fs_group = 472
        }

        container {
          name = local.grafana_name

          image             = "grafana/grafana:${var.grafana_tag}"
          image_pull_policy = "IfNotPresent"

          port {
            container_port = local.grafana_port
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.grafana_env.metadata[0].name
            }
          }

          env {
            name = "GF_SECURITY_ADMIN_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.grafana_admin.metadata[0].name
                key  = "username"
              }
            }
          }

          env {
            name = "GF_SECURITY_ADMIN_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.grafana_admin.metadata[0].name
                key  = "password"
              }
            }
          }

          volume_mount {
            name       = "datasources-provisioning"
            mount_path = "/provisioning/datasources"
          }

          volume_mount {
            name       = "data"
            mount_path = "/data"
          }

          liveness_probe {
            http_get {
              path = "/api/health"
              port = local.grafana_port
            }

            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "grafana" {
  metadata {
    name = local.grafana_name
  }

  spec {
    selector = local.grafana_labels

    type = var.service_type

    port {
      name = "http"
      port = local.grafana_port
      # SANDBOX ONLY node_port = local.grafana_port
    }
  }
}

resource "kubernetes_ingress" "grafana" {
  metadata {
    name = local.grafana_name
    annotations = {
      "kubernetes.io/ingress.class" = var.kubernetes_io_ingress_class
    }
  }

  spec {
    rule {
      host = local.grafana_host

      http {
        path {
          backend {
            service_name = kubernetes_service.grafana.metadata[0].name
            service_port = "http"
          }
        }
      }
    }
  }
}
