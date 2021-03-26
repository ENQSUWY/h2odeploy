locals {
  ambassador_name = "${var.prefix}-ambassador"
  model_host      = "model.${var.ingress_host}"

  ambassador_labels = {
    app       = "ambassador"
    prefix    = var.prefix
    component = "ambassador"
  }
}

resource "kubernetes_service_account" "ambassador" {
  metadata {
    namespace = var.namespace
    name      = local.ambassador_name
  }
  automount_service_account_token = true
}

resource "kubernetes_cluster_role" "ambassador" {
  metadata {
    name = local.ambassador_name
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["endpoints", "namespaces", "secrets", "services"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["getambassador.io"]
    resources  = ["*"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["networking.internal.knative.dev"]
    resources  = ["clusteringresses", "ingresses"]
  }

  rule {
    verbs      = ["update"]
    api_groups = ["networking.internal.knative.dev"]
    resources  = ["ingresses/status", "clusteringresses/status"]
  }
}

resource "kubernetes_cluster_role_binding" "ambassador" {
  metadata {
    name = local.ambassador_name
  }

  subject {
    namespace = var.namespace
    kind      = "ServiceAccount"
    name      = local.ambassador_name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = local.ambassador_name
  }
}

resource "kubernetes_deployment" "ambassador" {
  metadata {
    namespace = var.namespace
    name      = local.ambassador_name
  }

  spec {
    selector {
      match_labels = local.ambassador_labels
    }

    template {
      metadata {
        labels = local.ambassador_labels

        annotations = {
          "consul.hashicorp.com/connect-inject" = false
          "sidecar.istio.io/inject"             = false
        }
      }

      spec {
        container {
          name  = local.ambassador_name
          image = "quay.io/datawire/ambassador:${var.ambassador_tag}"

          port {
            name           = "http"
            container_port = 1080
          }

          port {
            name           = "admin"
            container_port = 8877
          }

          env {
            name = "AMBASSADOR_NAMESPACE"

            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }

          resources {
            limits {
              cpu    = "1"
              memory = "400Mi"
            }

            requests {
              cpu    = "200m"
              memory = "100Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/ambassador/v0/check_alive"
              port = "8877"
            }

            initial_delay_seconds = 30
            period_seconds        = 3
          }

          readiness_probe {
            http_get {
              path = "/ambassador/v0/check_ready"
              port = "8877"
            }

            initial_delay_seconds = 30
            period_seconds        = 3
          }
        }

        restart_policy                  = "Always"
        service_account_name            = kubernetes_service_account.ambassador.metadata[0].name
        automount_service_account_token = true

        security_context {
          run_as_user = 8888
        }
      }
    }
  }
}

resource "kubernetes_service" "ambassador" {
  metadata {
    namespace = var.namespace
    name      = local.ambassador_name

    annotations = {
      "getambassador.io/config" = templatefile("${path.module}/templates/ambassador.yaml",
        {
          ui_url = var.ui_public_url,
        }
      )
    }
  }

  spec {
    type = var.service_type

    port {
      name     = "http"
      protocol = "TCP"
      port     = 1080
      # SANDBOX ONLY node_port = 1080
    }

    port {
      name     = "admin"
      protocol = "TCP"
      port     = 8877
      # SANDBOX ONLY node_port = 8877
    }

    selector = local.ambassador_labels
  }
}

resource "kubernetes_service" "ambassador_admin" {
  metadata {
    namespace = var.namespace
    name      = "${local.ambassador_name}-admin"
  }

  spec {
    port {
      name        = "admin"
      port        = 80
      target_port = 8877
    }

    selector = local.ambassador_labels
  }
}

# Chain the ambassador ingress into the top-level traefik ingress.
# External packets can go to traefik on the HTTP port and then get handed to
# ambassador when using the model subdomain.
#
# This allows model prediction requests to flow in to the traefik in a manner
# consistent with other services.
#
# Before this config, the traefik and ambassador were only on separate ports
# and there was no linkage between them.  As a result, the
# "Show sample request" in the Model Manager UI did not work properly when
# there was no load balancer in front to route the requests to the different
# port.
#
# Note the ambassador is still listening on it's own port and is still
# reachable directly.
resource "kubernetes_ingress" "ambassador" {
  metadata {
    namespace = var.namespace
    name      = local.ambassador_name
    annotations = {
      "kubernetes.io/ingress.class" = var.kubernetes_io_ingress_class
    }
  }

  spec {
    rule {
      host = local.model_host

      http {
        path {
          backend {
            service_name = kubernetes_service.ambassador.metadata[0].name
            service_port = "http"
          }
        }
      }
    }
  }
}
