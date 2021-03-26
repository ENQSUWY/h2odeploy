locals {
  pdt           = var.platform_deployment_type
  PDT_SUBDOMAIN = "subdomain"
  PDT_NODE_PORT = "node_port"

  ingress_host = {
    # (local.PDT_SUBDOMAIN) = "${var.prefix}.${var.domain}",
    (local.PDT_SUBDOMAIN) = var.domain, 
    (local.PDT_NODE_PORT) = var.domain
  }[local.pdt]

  service_type = {
    (local.PDT_SUBDOMAIN) = "ClusterIP",
    (local.PDT_NODE_PORT) = "NodePort"
  }[local.pdt]
}

# module "eks_cluster" {
#   source = "./modules/eks_cluster"

#   prefix = var.prefix
#   domain = var.domain

#   admin_arns         = var.eks_admin_arns
#   admin_role_arn     = var.eks_admin_role_arn
#   node_count         = var.eks_node_count
#   node_instance_type = var.eks_node_instance_type
# }

provider "kubernetes" {
  # host                   = module.eks_cluster.kubernetes.endpoint
  # cluster_ca_certificate = base64decode(module.eks_cluster.kubernetes.ca_data)
  # token                  = module.eks_cluster.kubernetes.token
  load_config_file       = true
}

module "components" {
  source = "./modules/components"

  prefix       = var.prefix
  ingress_host = local.ingress_host
  protocol     = var.protocol
  namespace    = var.namespace

  platform_deployment_type     = var.platform_deployment_type
  service_type                 = local.service_type
  traefik_ingress_service_type = var.traefik_ingress_service_type
  kubernetes_io_ingress_class  = var.kubernetes_io_ingress_class

  driverless_image                   = var.driverless_image
  driverless_count                   = var.driverless_count
  driverless_license_path            = var.driverless_license_path
  storage_roles_bootstrap_input_file = var.storage_roles_bootstrap_input_file == "" ? "${path.module}/bootstrap-roles.hcl" : var.storage_roles_bootstrap_input_file

  grafana_anonymous_access = var.grafana_anonymous_access
  studio_access_mode       = var.studio_access_mode

  deployer_image                = var.deployer_image
  monitor_proxy_image           = var.monitor_proxy_image
  model_fetcher_image           = var.model_fetcher_image
  security_proxy_image          = var.security_proxy_image
  scorer_image                  = var.scorer_image
  storage_image                 = var.storage_image
  studio_image                  = var.studio_image
  ui_image                      = var.ui_image
  drift_detection_worker_image  = var.drift_detection_worker_image
  drift_detection_trigger_image = var.drift_detection_trigger_image
  model_ingestion_image         = var.model_ingestion_image
  gateway_image                 = var.gateway_image

  storage_data_volume_size    = var.storage_data_volume_size
  driverless_data_volume_size = var.driverless_data_volume_size
  influxdb_data_volume_size   = var.influxdb_data_volume_size
}
