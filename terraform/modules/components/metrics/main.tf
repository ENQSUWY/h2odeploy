locals {
  metrics_labels = {
    name = "metrics-server"
  }
}

resource "kubernetes_service_account" "metrics" {
  metadata {
    name      = "metrics-server"
    namespace = "kube-system"
  }
  automount_service_account_token = true
}

resource "kubernetes_cluster_role" "metrics" {
  metadata {
    namespace = var.namespace
    name      = "system:metrics-server"
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["pods", "nodes", "nodes/stats", "namespaces"]
  }
}

resource "kubernetes_cluster_role_binding" "metrics" {
  metadata {
    namespace = var.namespace
    name      = "system:metrics-server"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "metrics-server"
    namespace = "kube-system"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:metrics-server"
  }
}

resource "kubernetes_cluster_role" "metrics-reader" {
  metadata {
    namespace = var.namespace
    name      = "system:aggregated-metrics-reader"

    labels = {
      "rbac.authorization.k8s.io/aggregate-to-view"  = true
      "rbac.authorization.k8s.io/aggregate-to-edit"  = true
      "rbac.authorization.k8s.io/aggregate-to-admin" = true
    }
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["metrics.k8s.io"]
    resources  = ["pods", "nodes"]
  }
}

resource "kubernetes_service" "metrics" {
  metadata {
    namespace = var.namespace
    name      = "metrics-server"

    labels = {
      "kubernetes.io/name"            = "Metrics-server"
      "kubernetes.io/cluster-service" = "true"
    }
  }

  spec {
    port {
      name     = "https"
      protocol = "TCP"
      port     = 443
    }

    selector = local.metrics_labels
  }
}

resource "kubernetes_deployment" "metrics" {
  metadata {
    namespace = var.namespace
    name      = "metrics-server"
    labels    = local.metrics_labels
  }

  spec {
    selector {
      match_labels = local.metrics_labels
    }

    template {
      metadata {
        name   = "metrics-server"
        labels = local.metrics_labels
      }

      spec {

        volume {
          name = "tmp-dir"

          empty_dir {}
        }

        container {
          name              = "metrics-server"
          image             = "k8s.gcr.io/metrics-server-amd64:${var.metrics_tag}"
          image_pull_policy = "IfNotPresent"

          volume_mount {
            name       = "tmp-dir"
            mount_path = "/tmp"
          }

          args = ["--kubelet-preferred-address-types=InternalIP"]
        }

        service_account_name            = kubernetes_service_account.metrics.metadata[0].name
        automount_service_account_token = true
      }
    }
  }
}

resource "kubernetes_api_service" "metrics_api" {
  metadata {
    namespace = var.namespace
    name      = "v1beta1.metrics.k8s.io"
  }

  spec {
    service {
      name      = "metrics-server"
      namespace = "kube-system"
    }

    group                    = "metrics.k8s.io"
    group_priority_minimum   = 100
    insecure_skip_tls_verify = true
    version                  = "v1beta1"
    version_priority         = 100
  }
}

resource "kubernetes_cluster_role_binding" "metrics-api" {
  metadata {
    namespace = var.namespace
    name      = "metrics-server:system:auth-delegator"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "metrics-server"
    namespace = "kube-system"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }
}

resource "kubernetes_role_binding" "metrics-api" {
  metadata {
    namespace = var.namespace
    name      = "metrics-server-auth-reader"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "metrics-server"
    namespace = "kube-system"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "extension-apiserver-authentication-reader"
  }
}
