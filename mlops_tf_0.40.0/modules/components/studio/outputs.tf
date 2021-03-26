output "service" {
  value = {
    name                   = local.studio_name
    host                   = local.studio_host
    port                   = local.port
    node_port              = kubernetes_service.studio.spec[0].port[0].node_port
    load_balancer_ip       = coalescelist(kubernetes_service.studio.load_balancer_ingress, [{ ip : null }])[0].ip
    load_balancer_hostname = coalescelist(kubernetes_service.studio.load_balancer_ingress, [{ hostname : null }])[0].hostname
  }
}
