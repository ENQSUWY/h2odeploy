locals {
  client_secrets_name = "${local.keycloak_name}-oidc-client-secrets"
  client_ids = {
    driverless      = "h2oai-driverless"
    driverless_pkce = "h2oai-driverless-pkce"
    storage         = "h2oai-storage"
    ui              = "h2oai-storage-web"
    retrainer       = "h2oai-retrainer"
  }
}

resource "random_password" "ui_client_secret" {
  length = 32
}

resource "random_password" "storage_client_secret" {
  length = 32
}

resource "random_password" "driverless_client_secret" {
  length = 32
}

resource "random_password" "retrainer_client_secret" {
  length = 32
}

resource "kubernetes_secret" "keycloak_import" {
  metadata {
    namespace = var.namespace
    name      = "${local.keycloak_name}-import"
  }

  data = {
    "import.json" = templatefile("${path.module}/templates/keycloak_import.json",
      {
        realm_name = var.prefix

        ui_client_id     = local.client_ids.ui
        ui_client_secret = random_password.ui_client_secret.result
        ui_redirect_urls = var.oauth2_redirect_urls.ui

        storage_client_id     = local.client_ids.storage
        storage_client_secret = random_password.storage_client_secret.result

        driverless_client_id     = local.client_ids.driverless
        driverless_client_secret = random_password.driverless_client_secret.result
        driverless_redirect_urls = var.oauth2_redirect_urls.driverless

        driverless_pkce_client_id = local.client_ids.driverless_pkce

        retrainer_client_id     = local.client_ids.retrainer
        retrainer_client_secret = random_password.retrainer_client_secret.result
    })
  }
}

resource "kubernetes_secret" "client_secrets" {
  metadata {
    namespace = var.namespace
    name      = local.client_secrets_name
  }

  data = {
    ui_client_secret         = random_password.ui_client_secret.result
    storage_client_secret    = random_password.storage_client_secret.result
    driverless_client_secret = random_password.driverless_client_secret.result
    retrainer_client_secret  = random_password.retrainer_client_secret.result
  }
}
