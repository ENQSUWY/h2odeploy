locals {
  traefik_name = "${var.prefix}-traefik"

  traefik_labels = {
    app                             = "traefik"
    prefix                          = var.prefix
    component                       = "traefik"
    k8s-app                         = "${local.traefik_name}-ingress-lb"
    name                            = "${local.traefik_name}-ingress-lb"
    "kubernetes.io/cluster-service" = true
  }
}

resource "kubernetes_service_account" "traefik_ingress_controller" {
  metadata {
    name = "${local.traefik_name}-ingress-controller"
  }

  automount_service_account_token = true
}

resource "kubernetes_daemonset" "traefik_ingress_controller" {
  metadata {
    name = "${local.traefik_name}-ingress-controller"
  }

  spec {
    selector {
      match_labels = local.traefik_labels
    }
    template {
      metadata {
        labels = local.traefik_labels
      }

      spec {
        container {
          name  = "traefik-ingress-lb"
          image = "traefik:${var.traefik_tag}"
          args  = ["--api", "--web", "--kubernetes", "--logLevel=DEBUG"]

          port {
            name           = "http"
            host_port      = 80
            container_port = 80
          }

          port {
            name           = "admin"
            host_port      = 8080
            container_port = 8080
          }

          security_context {
            capabilities {
              drop = ["ALL"]
              add  = ["NET_BIND_SERVICE"]
            }
          }
        }

        termination_grace_period_seconds = 60
        service_account_name             = kubernetes_service_account.traefik_ingress_controller.metadata[0].name
        automount_service_account_token  = true
      }
    }
  }
}

resource "kubernetes_service" "traefik_ingress_service" {
  metadata {
    name = "${local.traefik_name}-ingress-service"
  }

  spec {
    type = var.traefik_ingress_service_type

    port {
      name     = "web"
      protocol = "TCP"
      port     = 80
    }

    port {
      name     = "admin"
      protocol = "TCP"
      port     = 8080
    }

    selector = {
      k8s-app = "${local.traefik_name}-ingress-lb"
    }
  }
}

resource "kubernetes_cluster_role" "traefik_ingress_controller" {
  metadata {
    name = "${local.traefik_name}-ingress-controller"
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["services", "endpoints", "secrets"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["extensions"]
    resources  = ["ingresses"]
  }

  rule {
    verbs      = ["update"]
    api_groups = ["extensions"]
    resources  = ["ingresses/status"]
  }
}

resource "kubernetes_cluster_role_binding" "traefik_ingress_controller" {
  metadata {
    name = "${local.traefik_name}-ingress-controller"
  }

  subject {
    kind = "ServiceAccount"
    name = "${local.traefik_name}-ingress-controller"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "${local.traefik_name}-ingress-controller"
  }
}

resource "kubernetes_service" "traefik_web_ui_service" {
  metadata {
    name = "${local.traefik_name}-web-ui"
  }

  spec {
    port {
      name        = "web"
      port        = 80
      target_port = 8080
    }

    selector = {
      k8s-app = "${local.traefik_name}-ingress-lb"
    }
  }
}
