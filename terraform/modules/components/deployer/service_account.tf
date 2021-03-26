# Deployer needs to have administrative rights in order to be able to spin-up
# the deployments.

resource "kubernetes_service_account" "deployer_service_account" {
  metadata {
    namespace = var.namespace
    name      = "${var.prefix}-deployer-service-account"
  }
}

data "kubernetes_secret" "deployer_service_account" {
  metadata {
    namespace = var.namespace
    name      = kubernetes_service_account.deployer_service_account.default_secret_name
  }
}

resource "kubernetes_cluster_role_binding" "deployer" {
  metadata {
    name = local.deployer_name
  }

  subject {
    namespace = var.environment_namespace
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.deployer_service_account.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
}
