locals {
  deployer_name = "${var.prefix}-deployer"

  deployer_labels = {
    app       = "h2oai-serving-deployer"
    prefix    = var.prefix
    component = "deployer"
  }

  deployer_port = 9980

  deployer_cacert_lines = split("\n", data.kubernetes_secret.deployer_service_account.data["ca.crt"])
  deployer_cacert_data  = join("", slice(local.deployer_cacert_lines, 1, length(local.deployer_cacert_lines) - 2))
}

resource "kubernetes_config_map" "deployer_config" {
  metadata {
    name = "${local.deployer_name}-config"
  }

  data = {
    "application.conf" = templatefile("${path.module}/templates/deployer.conf",
      {
        storage_host = var.storage_service.name
        storage_port = var.storage_service.port

        grafana_public_url   = var.grafana_public_url
        grafana_internal_url = var.grafana_internal_url
        grafana_api_token    = var.grafana_api_token

        influxdb_url = var.influxdb_internal_url

        service_account_token = data.kubernetes_secret.deployer_service_account.data.token
        ca_cert_data          = local.deployer_cacert_data

        driverless_license_secret_name = var.driverless_license_secret_name
        fetcher_client_secret_name     = var.model_fetcher_tls_client_secret_name
        fetcher_ca_secret_name         = var.ca_secret_name

        deployer_port = local.deployer_port

        scorer_public_url        = var.scorer_public_url
        fetcher_docker_image     = var.model_fetcher_image
        scorer_mojo_docker_image = var.scorer_image
        monitor_docker_image     = var.monitor_proxy_image
        security_docker_image    = var.security_proxy_image
      }
    )
  }
}

resource "kubernetes_deployment" "deployer" {
  metadata {
    name   = local.deployer_name
    labels = local.deployer_labels
  }

  spec {
    selector {
      match_labels = local.deployer_labels
    }

    template {
      metadata {
        labels = local.deployer_labels
      }

      spec {
        volume {
          name = "config"

          config_map {
            name = kubernetes_config_map.deployer_config.metadata[0].name
            items {
              key  = "application.conf"
              path = "application.conf"
            }
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
          name = "tls-client"

          secret {
            secret_name = var.tls_client_secret_name
          }
        }

        container {
          name = local.deployer_name

          image             = var.deployer_image
          image_pull_policy = "IfNotPresent"

          command = ["java"]
          args = [
            "-Dconfig.file=/config/application.conf",
            "-classpath", "/app/classpath/*:/app/libs/*",
            "ai.h2o.deploy.deployer.Deployer",
          ]

          env {
            # Mojo library also needs Driverless licence set in order to parse
            # and augment mojo for the deployment.
            name = "DRIVERLESS_AI_LICENSE_KEY"
            value_from {
              secret_key_ref {
                name = var.driverless_license_secret_name
                key  = "license.sig"
              }
            }

          }

          port {
            container_port = local.deployer_port
          }

          volume_mount {
            name       = "config"
            mount_path = "/config"
          }

          volume_mount {
            name       = "tls-ca"
            mount_path = "/pki/ca"
          }

          volume_mount {
            name       = "tls-client"
            mount_path = "/pki/client"
          }

          volume_mount {
            name       = "tls-server"
            mount_path = "/pki/server"
          }

          liveness_probe {
            tcp_socket {
              port = local.deployer_port
            }

            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "deployer" {
  metadata {
    name = local.deployer_name
  }

  spec {
    selector = local.deployer_labels

    type = var.service_type

    port {
      port = local.deployer_port
    }
  }
}
