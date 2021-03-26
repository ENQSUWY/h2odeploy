# output "eks_cluster_name" {
#   value = module.eks_cluster.cluster_name
# }

# output "eks_cluster_auth" {
#   value = {
#     ca_data = base64decode(module.eks_cluster.kubernetes.ca_data)
#     token   = module.eks_cluster.kubernetes.token
#   }
#   sensitive = true
# }

# output "driverless_services" {
#   value = module.components.driverless_services
# }

output "ui_service" {
  value = module.components.ui_service
}

output "grafana_service" {
  value = module.components.grafana_service
}

output "studio_service" {
  value = module.components.studio_service
}

output "keycloak_service" {
  value = module.components.keycloak_service
}

output "keycloak_admin_password" {
  value     = module.components.keycloak_admin_password
  sensitive = true
}

output "grafana_admin_password" {
  value     = module.components.grafana_admin_password
  sensitive = true
}
