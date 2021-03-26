resource "kubernetes_service_account" "studio" {
  metadata {
    name = "studio"
  }
}

resource "kubernetes_role" "studio" {
  metadata {
    name = "studio"
  }

  rule {
    api_groups     = [""]
    resources      = ["secrets"]
    resource_names = [var.license_secret_name]
    verbs          = ["delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["create"]
  }

  rule {
    api_groups     = ["apps"]
    resources      = ["deployments"]
    resource_names = [var.deployer_deployment_name]
    verbs          = ["get"]
  }

  rule {
    api_groups     = ["apps"]
    resources      = ["deployments/scale"]
    resource_names = [var.deployer_deployment_name]
    verbs          = ["patch"]
  }
}

resource "kubernetes_role_binding" "studio" {
  metadata {
    name = "studio"
  }

  subject {
    kind = "ServiceAccount"
    name = kubernetes_service_account.studio.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.studio.metadata[0].name
  }
}
