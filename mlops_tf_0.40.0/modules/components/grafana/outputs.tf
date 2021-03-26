output "service" {
  value = {
    name                   = local.grafana_name
    host                   = local.grafana_host
    port                   = local.grafana_port
    node_port              = kubernetes_service.grafana.spec[0].port[0].node_port
    load_balancer_ip       = coalescelist(kubernetes_service.grafana.load_balancer_ingress, [{ ip : null }])[0].ip
    load_balancer_hostname = coalescelist(kubernetes_service.grafana.load_balancer_ingress, [{ hostname : null }])[0].hostname
  }
}

output "admin_password" {
  value     = kubernetes_secret.grafana_admin.data
  sensitive = true
}

output "internal_url" {
  value = "http://${local.grafana_name}:${local.grafana_port}"
}
