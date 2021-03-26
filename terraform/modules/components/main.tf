locals {
  # Platform deployment type control variable and constants.
  pdt           = var.platform_deployment_type
  PDT_SUBDOMAIN = "subdomain"
  PDT_NODE_PORT = "node_port"

  ui_public_url = {
    (local.PDT_SUBDOMAIN) = "${var.protocol}://${module.ui.service.host}"
    (local.PDT_NODE_PORT) = "${var.protocol}://${var.ingress_host}:${module.ui.service.node_port}"
  }[local.pdt]

  keycloak_frontend_url = {
    (local.PDT_SUBDOMAIN) = "${var.protocol}://keycloak.${var.ingress_host}/auth/"
    (local.PDT_NODE_PORT) = "${var.protocol}://${var.ingress_host}:${module.keycloak.service.node_port}/auth/"
  }[local.pdt]

  ui_oauth2_redirect_url = {
    (local.PDT_SUBDOMAIN) = "${var.protocol}://${module.ui.service.host}/*"
    (local.PDT_NODE_PORT) = "*"
  }[local.pdt]

  oidc_identity_provider_url = {
    (local.PDT_SUBDOMAIN) = "${var.protocol}://${module.keycloak.service.host}/${module.keycloak.oidc_identity_provider_url_path}"
    (local.PDT_NODE_PORT) = "${var.protocol}://${var.ingress_host}:${module.keycloak.service.node_port}/${module.keycloak.oidc_identity_provider_url_path}"
  }[local.pdt]

  oidc_introspection_url = {
    (local.PDT_SUBDOMAIN) = "${var.protocol}://${module.keycloak.service.host}/${module.keycloak.oidc_introspection_url_path}"
    (local.PDT_NODE_PORT) = "${var.protocol}://${var.ingress_host}:${module.keycloak.service.node_port}/${module.keycloak.oidc_introspection_url_path}"
  }[local.pdt]

  oidc_end_session_url = {
    (local.PDT_SUBDOMAIN) = "${var.protocol}://${module.keycloak.service.host}/${module.keycloak.oidc_end_session_url_path}"
    (local.PDT_NODE_PORT) = "${var.protocol}://${var.ingress_host}:${module.keycloak.service.node_port}/${module.keycloak.oidc_end_session_url_path}"
  }[local.pdt]

  scorer_public_url = {
    (local.PDT_SUBDOMAIN) = "${var.protocol}://model.${var.ingress_host}"
    (local.PDT_NODE_PORT) = "${var.protocol}://${var.ingress_host}:${module.ambassador.service.node_port}"
  }[local.pdt]

  grafana_public_url = {
    (local.PDT_SUBDOMAIN) = "${var.protocol}://${module.grafana.service.host}"
    (local.PDT_NODE_PORT) = "${var.protocol}://${var.ingress_host}:${module.grafana.service.node_port}"
  }[local.pdt]

  studio_driverless_address = {
    (local.PDT_SUBDOMAIN) = "${var.protocol}://steam.40-71-236-86.h2o.sslip.io"
    (local.PDT_NODE_PORT) = "${var.protocol}://steam.40-71-236-86.h2o.sslip.io"
  }[local.pdt]

  studio_keycloak_address = {
    (local.PDT_SUBDOMAIN) = "${var.protocol}://${module.keycloak.service.host}"
    (local.PDT_NODE_PORT) = "${var.protocol}://${var.ingress_host}:${module.keycloak.service.node_port}"
  }[local.pdt]
}

module "pki" {
  source = "./pki"

  namespace = var.namespace
  prefix    = var.prefix

  spiffe_trust_domain  = var.ingress_host
  components_namespace = var.namespace

  tls_servers = [
    "deployer",
    "storage",
    "ingestion"
  ]

  tls_clients = {
    deployer = {
      spiffe : true,
    },
    driverless = {
      spiffe : false,
    },
    ui = {
      spiffe : false,
    },
    ingestion = {
      spiffe : false,
    },
    gateway = {
      spiffe : false,
    },
    fetcher = {
      spiffe : true,
    }
  }
}

module "ambassador" {
  source = "./ambassador"

  namespace    = var.namespace
  prefix       = var.prefix
  service_type = var.service_type
  ingress_host = var.ingress_host

  kubernetes_io_ingress_class = var.kubernetes_io_ingress_class

  ui_public_url = local.ui_public_url
}

# module "traefik" {
#   source = "./traefik"

#   namespace                    = var.namespace
#   prefix                       = var.prefix
#   traefik_ingress_service_type = var.traefik_ingress_service_type
# }

module "keycloak" {
  source = "./keycloak"

  namespace    = var.namespace
  prefix       = var.prefix
  service_type = var.service_type
  ingress_host = var.ingress_host

  kubernetes_io_ingress_class = var.kubernetes_io_ingress_class

  frontend_url = local.keycloak_frontend_url

  keycloak_tag = var.keycloak_tag

  // TODO(osery, h2oai/h2oai-storage-web#498): Find a way to get these without creating cyclic
  // module dependencies.
  oauth2_redirect_urls = {
    ui = [
      local.ui_oauth2_redirect_url
    ],
    driverless = [
      for i in range(var.driverless_count) :
      (local.pdt == local.PDT_SUBDOMAIN) ? "${var.protocol}://driverless-${format("%02d", i + 1)}.${var.ingress_host}/*" : (local.pdt == local.PDT_NODE_PORT ? "*" : "unknown")
    ],
  }
}

module "influxdb" {
  source = "./influxdb"

  namespace    = var.namespace
  prefix       = var.prefix
  service_type = var.service_type

  data_volume_size = var.influxdb_data_volume_size
}

module "prometheus" {
  source = "./prometheus"

  namespace    = var.namespace
  prefix       = var.prefix
  service_type = var.service_type
}

module "grafana" {
  source = "./grafana"

  namespace    = var.namespace
  prefix       = var.prefix
  service_type = var.service_type
  ingress_host = var.ingress_host

  kubernetes_io_ingress_class = var.kubernetes_io_ingress_class

  influxdb_internal_url   = module.influxdb.internal_url
  prometheus_internal_url = module.prometheus.internal_url

  anonymous_access = var.grafana_anonymous_access
}

provider "grafanaauth" {
  url      = local.grafana_public_url
  username = module.grafana.admin_password.username
  password = module.grafana.admin_password.password
}

module "grafana-auth" {
  source = "./grafana-auth"

  admin_key_name  = "deployer-key"
  viewer_key_name = "ui-key"

  depends_on = [module.grafana]
}

module "chronograf" {
  source = "./chronograf"

  namespace    = var.namespace
  prefix       = var.prefix
  service_type = var.service_type

  influxdb_internal_url = module.influxdb.internal_url
}

# For clusters that don't have the metrics server already enabled in
# kube-system, you can enable it by uncommenting the lines below.
# But by default, we don't want to install any cluster-level services
# into kube-system at all.

# module "metrics" {
#   source = "./metrics"
#
#   namespace = var.namespace
# }

module "postgres" {
  source = "./postgres"

  namespace    = var.namespace
  prefix       = var.prefix
  service_type = var.service_type

  storage_db = "h2oai_storage"
}

module "driverless" {
  source = "./driverless"

  namespace    = var.namespace
  prefix       = var.prefix
  service_type = var.service_type
  ingress_host = var.ingress_host

  kubernetes_io_ingress_class = var.kubernetes_io_ingress_class

  driverless_image        = var.driverless_image
  driverless_count        = var.driverless_count
  driverless_license_path = var.driverless_license_path
  driverless_urls = {
    urls = [
      for i in range(var.driverless_count) :
      (local.pdt == local.PDT_SUBDOMAIN) ? "${var.protocol}://driverless-${format("%02d", i + 1)}.${var.ingress_host}" : (local.pdt == local.PDT_NODE_PORT ? "${var.protocol}://${var.ingress_host}:${module.driverless.services[i].node_port}" : "unknown")
    ],
  }

  client_id                  = module.keycloak.client_ids.driverless
  pkce_client_id             = module.keycloak.client_ids.driverless_pkce
  client_secrets_name        = module.keycloak.client_secrets_name
  oidc_identity_provider_url = local.oidc_identity_provider_url
  oidc_introspection_url     = local.oidc_introspection_url
  ca_secret_name             = module.pki.ca_secret_name
  tls_client_secret_name     = module.pki.tls_client_secrets_names["driverless"]

  storage_service = module.storage.service

  volume_size = var.driverless_data_volume_size
}

module "storage" {
  source = "./storage"

  namespace    = var.namespace
  prefix       = var.prefix
  service_type = var.service_type
  ingress_host = var.ingress_host

  storage_image = var.storage_image

  client_id              = module.keycloak.client_ids.storage
  client_secrets_name    = module.keycloak.client_secrets_name
  oidc_introspection_url = local.oidc_introspection_url
  ca_secret_name         = module.pki.ca_secret_name
  tls_server_secret_name = module.pki.tls_server_secrets_names["storage"]

  database_driver                  = "postgres"
  database_credentials_secret_name = module.postgres.storage_connection_string_secret_name
  database_connection_key_name     = module.postgres.storage_connection_string_key_name

  roles_bootstrap_input_file = var.storage_roles_bootstrap_input_file

  volume_size = var.storage_data_volume_size
}

module "deployer" {
  source = "./deployer"

  namespace    = var.namespace
  prefix       = var.prefix
  service_type = var.service_type
  ingress_host = var.ingress_host

  deployer_image       = var.deployer_image
  model_fetcher_image  = var.model_fetcher_image
  monitor_proxy_image  = var.monitor_proxy_image
  scorer_image         = var.scorer_image
  security_proxy_image = var.security_proxy_image

  scorer_public_url     = local.scorer_public_url
  grafana_internal_url  = module.grafana.internal_url
  grafana_public_url    = local.grafana_public_url
  influxdb_internal_url = module.influxdb.internal_url

  # TODO(zoido): Have this external.
  driverless_license_secret_name       = module.driverless.license_secret_name
  model_fetcher_tls_client_secret_name = module.pki.tls_client_secrets_names["fetcher"]
  grafana_api_token                    = module.grafana-auth.admin_api_key

  environment_namespace  = var.namespace
  ca_secret_name         = module.pki.ca_secret_name
  tls_client_secret_name = module.pki.tls_client_secrets_names["deployer"]
  tls_server_secret_name = module.pki.tls_server_secrets_names["deployer"]

  storage_service = module.storage.service
}

module "ui" {
  source = "./ui"

  namespace    = var.namespace
  prefix       = var.prefix
  service_type = var.service_type
  ingress_host = var.ingress_host

  kubernetes_io_ingress_class = var.kubernetes_io_ingress_class

  ui_image = var.ui_image

  cookie_secure = var.protocol == "https" ? true : false

  base_url             = local.ui_public_url
  grafana_internal_url = module.grafana.internal_url
  grafana_api_token    = module.grafana-auth.viewer_api_key

  client_id                  = module.keycloak.client_ids.ui
  client_secrets_name        = module.keycloak.client_secrets_name
  oidc_identity_provider_url = local.oidc_identity_provider_url
  oidc_introspection_url     = local.oidc_introspection_url
  oidc_end_session_url       = "${local.oidc_end_session_url}?post_logout_redirect_uri=${local.ui_public_url}"
  ca_secret_name             = module.pki.ca_secret_name
  tls_client_secret_name     = module.pki.tls_client_secrets_names["ui"]

  storage_service         = module.storage.service
  deployer_service        = module.deployer.service
  model_ingestion_service = module.ingestion.service
}

module "drift-detection-worker" {
  source = "./drift-detection-worker"

  namespace                    = var.namespace
  prefix                       = var.prefix
  drift_detection_worker_image = var.drift_detection_worker_image

  rabbitmq_drift_secrets = module.rabbitmq.rabbitmq_drift_secret_name
  rabbitmq_service       = module.rabbitmq.service
  influx_service         = module.influxdb.service
}

module "rabbitmq" {
  source = "./rabbitmq"

  namespace    = var.namespace
  prefix       = var.prefix
  service_type = var.service_type
}

module "drift-detection-trigger" {
  source = "./drift-detection-trigger"

  namespace                     = var.namespace
  prefix                        = var.prefix
  drift_detection_trigger_image = var.drift_detection_trigger_image

  rabbitmq_drift_secrets = module.rabbitmq.rabbitmq_drift_secret_name
  rabbitmq_service       = module.rabbitmq.service
  influx_service         = module.influxdb.service
}

module "studio" {
  source = "./studio"

  namespace    = var.namespace
  prefix       = var.prefix
  service_type = var.service_type
  ingress_host = var.ingress_host

  kubernetes_io_ingress_class = var.kubernetes_io_ingress_class

  studio_image = var.studio_image

  demo_mode                = var.studio_access_mode == "demo"
  license_secret_name      = module.driverless.license_secret_name
  deployer_deployment_name = module.deployer.service.name

  driverless_ai_credentials = {
    address  = local.studio_driverless_address
    username = null
    password = null
  }

  model_ops_credentials = {
    address  = local.ui_public_url
    username = null
    password = null
  }

  user_management_credentials = {
    address  = local.studio_keycloak_address
    username = null
    password = null
  }
}

module "ingestion" {
  source                = "./ingestion"
  model_ingestion_image = var.model_ingestion_image

  namespace    = var.namespace
  prefix       = var.prefix
  service_type = var.service_type

  ca_secret_name         = module.pki.ca_secret_name
  tls_server_secret_name = module.pki.tls_server_secrets_names["ingestion"]
  tls_client_secret_name = module.pki.tls_client_secrets_names["ingestion"]

  storage_service = module.storage.service
}

module "gateway" {
  source = "./gateway"

  namespace    = var.namespace
  prefix       = var.prefix
  service_type = var.service_type
  ingress_host = var.ingress_host

  kubernetes_io_ingress_class = var.kubernetes_io_ingress_class

  gateway_image = var.gateway_image

  ca_secret_name         = module.pki.ca_secret_name
  tls_client_secret_name = module.pki.tls_client_secrets_names["ui"]

  storage_service         = module.storage.service
  deployer_service        = module.deployer.service
  model_ingestion_service = module.ingestion.service
}
