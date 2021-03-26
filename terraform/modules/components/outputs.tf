# output "driverless_services" {
#   value = module.driverless.services
# }

# output "driverless_ingresses" {
#   value = module.driverless.ingresses
# }

output "ui_service" {
  value = module.ui.service
}

output "grafana_service" {
  value = module.grafana.service
}

output "studio_service" {
  value = module.studio.service
}

output "keycloak_service" {
  value = module.keycloak.service
}

output "keycloak_admin_password" {
  value     = module.keycloak.admin_password
  sensitive = true
}

output "grafana_admin_password" {
  value     = module.grafana.admin_password.password
  sensitive = true
}
