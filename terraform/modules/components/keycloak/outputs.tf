output "service" {
  value = {
    name                   = local.keycloak_name
    host                   = local.keycloak_host
    port                   = local.keycloak_port
    node_port              = kubernetes_service.keycloak.spec[0].port[0].node_port
    load_balancer_ip       = coalescelist(kubernetes_service.keycloak.load_balancer_ingress, [{ ip : null }])[0].ip
    load_balancer_hostname = coalescelist(kubernetes_service.keycloak.load_balancer_ingress, [{ hostname : null }])[0].hostname
  }
}

output "admin_password" {
  value     = kubernetes_secret.keycloak_admin.data.password
  sensitive = true
}

output "client_ids" {
  value = local.client_ids
}

output "client_secrets_name" {
  value = local.client_secrets_name
}

output "oidc_identity_provider_url_path" {
  value = "auth/realms/${var.prefix}"
}

output "oidc_introspection_url_path" {
  value = "auth/realms/${var.prefix}/protocol/openid-connect/token/introspect"
}

output "oidc_end_session_url_path" {
  value = "auth/realms/${var.prefix}/protocol/openid-connect/logout"
}
