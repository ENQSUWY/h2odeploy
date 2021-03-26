output "service" {
  value = {
    name                   = local.q_name
    host                   = local.q_host
    port                   = local.port
    node_port              = kubernetes_service.q.spec[0].port[0].node_port
    load_balancer_ip       = coalescelist(kubernetes_service.q.load_balancer_ingress, [{ ip : null }])[0].ip
    load_balancer_hostname = coalescelist(kubernetes_service.q.load_balancer_ingress, [{ hostname : null }])[0].hostname
  }
}

output "admin_password" {
  value     = kubernetes_secret.q_admin.data.password
  sensitive = true
}
