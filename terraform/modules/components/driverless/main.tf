locals {
  driverless_name = "${var.prefix}-driverless"

  driverless_labels = {
    app       = "h2o-driverless"
    prefix    = var.prefix
    component = "driverless"
  }

  driverless_port = 12345
}

# resource "kubernetes_persistent_volume_claim" "driverless_tmp" {
#   count = var.driverless_count

#   metadata {
#     name = "${local.driverless_name}-${format("%02d", count.index + 1)}-tmp"
#     labels = merge(
#       local.driverless_labels,
#       {
#         "index" = count.index + 1
#       },
#     )
#   }

#   spec {
#     access_modes = ["ReadWriteOnce"]

#     resources {
#       requests = {
#         storage = "${var.volume_size}Gi"
#       }
#     }
#   }

#   wait_until_bound = false
# }

# resource "kubernetes_config_map" "driverless_env" {
#   metadata {
#     name = "${local.driverless_name}-env"
#   }

#   data = {
#     DAI_H2O_STORAGE_ADDRESS          = "${var.storage_service.name}:${var.storage_service.port}"
#     DAI_H2O_STORAGE_PROJECTS_ENABLED = true

#     DRIVERLESS_AI_H2O_STORAGE_TLS_ENABLED   = 1
#     DRIVERLESS_AI_H2O_STORAGE_TLS_CA_PATH   = "/pki/ca/certificate"
#     DRIVERLESS_AI_H2O_STORAGE_TLS_CERT_PATH = "/pki/client/certificate"
#     DRIVERLESS_AI_H2O_STORAGE_TLS_KEY_PATH  = "/pki/client/key"

#     DRIVERLESS_AI_MEMORY_LIMIT_GB            = 1
#     DRIVERLESS_AI_DISK_LIMIT_GB              = 1
#     DRIVERLESS_AI_USE_UUIDS                  = 1
#     DRIVERLESS_AI_PROTECT_BASE_ENV           = 0
#     DRIVERLESS_AI_ENABLE_ACCEPTANCE_TESTS    = 0
#     DRIVERLESS_AI_SERVER_RECIPE_URL          = ""
#     DRIVERLESS_AI_ENABLE_TENSORFLOW_IMPORT   = 0
#     DRIVERLESS_AI_LICENSE_FILE               = "/license/license.sig"
#     DRIVERLESS_AI_MAKE_MOJO_SCORING_PIPELINE = "on"

#     DRIVERLESS_AI_AUTHENTICATION_METHOD               = "openid"
#     DRIVERLESS_AI_AUTH_OPENID_PROVIDER_BASE_URI       = "${var.oidc_identity_provider_url}/"
#     DRIVERLESS_AI_AUTH_OPENID_CONFIGURATION_URI       = ".well-known/openid-configuration"
#     DRIVERLESS_AI_AUTH_OPENID_AUTH_URI                = "protocol/openid-connect/auth"
#     DRIVERLESS_AI_AUTH_OPENID_TOKEN_URI               = "protocol/openid-connect/token"
#     DRIVERLESS_AI_AUTH_OPENID_USERINFO_URI            = "protocol/openid-connect/userinfo"
#     DRIVERLESS_AI_AUTH_OPENID_TOKEN_INTROSPECTION_URL = var.oidc_introspection_url
#     DRIVERLESS_AI_AUTH_OPENID_RESPONSE_TYPE           = "code"
#     DRIVERLESS_AI_AUTH_OPENID_CLIENT_ID               = var.client_id
#     DRIVERLESS_AI_AUTH_OPENID_SCOPE                   = "openid profile email ai.h2o.storage"
#     DRIVERLESS_AI_AUTH_OPENID_GRANT_TYPE              = "authorization_code"
#     DRIVERLESS_AI_AUTH_OPENID_USERINFO_USERNAME_KEY   = "preferred_username"

#     DRIVERLESS_AI_API_TOKEN_INTROSPECTION_ENABLED      = true
#     DRIVERLESS_AI_API_TOKEN_INTROSPECTION_METHOD       = "OAUTH2_TOKEN_INTROSPECTION"
#     DRIVERLESS_AI_API_TOKEN_OAUTH2_USERNAME_FIELD_NAME = "username"

#     DRIVERLESS_AI_OAUTH2_CLIENT_TOKENS_ENABLED           = true
#     DRIVERLESS_AI_OAUTH2_CLIENT_TOKENS_CLIENT_ID         = var.pkce_client_id
#     DRIVERLESS_AI_OAUTH2_CLIENT_TOKENS_AUTHORIZE_URL     = "${var.oidc_identity_provider_url}/protocol/openid-connect/auth"
#     DRIVERLESS_AI_OAUTH2_CLIENT_TOKENS_TOKEN_URL         = "${var.oidc_identity_provider_url}/protocol/openid-connect/token"
#     DRIVERLESS_AI_OAUTH2_CLIENT_TOKENS_INTROSPECTION_URL = var.oidc_introspection_url
#     DRIVERLESS_AI_OAUTH2_CLIENT_TOKENS_SCOPE             = "profile ai.h2o.storage ai.h2o.driverless"

#     DRIVERLESS_AI_WORKER_MODE = "multiprocessing"
#   }
# }

# resource "kubernetes_deployment" "driverless" {
#   count = var.driverless_count

#   timeouts {
#     # Driverless image pull can take significant amount of time due to its enormous size.
#     create = "12m"
#   }

#   metadata {
#     name = "${local.driverless_name}-${format("%02d", count.index + 1)}"
#     labels = merge(
#       local.driverless_labels,
#       {
#         "index" = count.index + 1
#       },
#     )
#   }

#   spec {
#     strategy {
#       // Due to the volume claims, we cannot do a RollingUpdate here. As the claims would block the
#       // new instance(s) from ever becoming healthy, thus blocking the update forever.
#       type = "Recreate"
#     }

#     selector {
#       match_labels = merge(
#         local.driverless_labels,
#         {
#           index = count.index + 1
#         },
#       )
#     }

#     template {
#       metadata {
#         labels = merge(
#           local.driverless_labels,
#           {
#             index = count.index + 1
#           },
#         )
#       }

#       spec {
#         volume {
#           name = "tmp"

#           persistent_volume_claim {
#             claim_name = "${local.driverless_name}-${format("%02d", count.index + 1)}-tmp"
#           }
#         }

#         volume {
#           name = "license"

#           secret {
#             secret_name = kubernetes_secret.driverless_license.metadata[0].name
#             items {
#               key  = "license.sig"
#               path = "license.sig"
#             }
#           }
#         }

#         volume {
#           name = "tls-ca"

#           secret {
#             secret_name = var.ca_secret_name
#           }
#         }

#         volume {
#           name = "tls-client"

#           secret {
#             secret_name = var.tls_client_secret_name
#           }
#         }

#         container {
#           name = "${local.driverless_name}-${format("%02d", count.index + 1)}"

#           image             = var.driverless_image
#           image_pull_policy = "IfNotPresent"

#           port {
#             container_port = local.driverless_port
#           }

#           volume_mount {
#             name       = "tmp"
#             mount_path = "/tmp"
#           }

#           volume_mount {
#             name       = "license"
#             mount_path = "/license"
#             read_only  = true
#           }

#           env_from {
#             config_map_ref {
#               name = kubernetes_config_map.driverless_env.metadata[0].name
#             }
#           }

#           env {
#             name  = "DRIVERLESS_AI_AUTH_OPENID_REDIRECT_URI"
#             value = "${var.driverless_urls.urls[count.index]}/openid/callback"
#           }

#           env {
#             name  = "DRIVERLESS_AI_OAUTH2_CLIENT_TOKENS_REDIRECT_URL"
#             value = "${var.driverless_urls.urls[count.index]}/oauth2/client_token"
#           }

#           env {
#             name = "DRIVERLESS_AI_AUTH_OPENID_CLIENT_SECRET"
#             value_from {
#               secret_key_ref {
#                 name = var.client_secrets_name
#                 key  = "driverless_client_secret"
#               }
#             }
#           }

#           volume_mount {
#             name       = "tls-ca"
#             mount_path = "/pki/ca"
#           }

#           volume_mount {
#             name       = "tls-client"
#             mount_path = "/pki/client"
#           }

#         }
#       }
#     }
#   }
# }

# resource "kubernetes_service" "driverless" {
#   count = var.driverless_count

#   metadata {
#     name = "${local.driverless_name}-${format("%02d", count.index + 1)}"
#   }

#   spec {
#     selector = merge(
#       local.driverless_labels,
#       {
#         index = count.index + 1
#       },
#     )

#     type = var.service_type

#     port {
#       name = "http"
#       port = local.driverless_port
#       # SANDBOX ONLY node_port = local.driverless_port
#     }
#   }
# }

# resource "kubernetes_ingress" "driverless" {
#   count = var.driverless_count

#   metadata {
#     name = "${local.driverless_name}-${format("%02d", count.index + 1)}"
#     annotations = {
#       "kubernetes.io/ingress.class" = var.kubernetes_io_ingress_class
#     }
#   }

#   spec {
#     rule {
#       host = "driverless-${format("%02d", count.index + 1)}.${var.ingress_host}"

#       http {
#         path {
#           backend {
#             service_name = kubernetes_service.driverless[count.index].metadata[0].name
#             service_port = "http"
#           }
#         }
#       }
#     }
#   }
# }
