output "service" {
  value = {
    name                   = local.gateway_name
    host                   = local.gateway_host
    port                   = local.gateway_port
    node_port              = kubernetes_service.gateway.spec[0].port[0].node_port
    load_balancer_ip       = coalescelist(kubernetes_service.gateway.load_balancer_ingress, [{ ip : null }])[0].ip
    load_balancer_hostname = coalescelist(kubernetes_service.gateway.load_balancer_ingress, [{ hostname : null }])[0].hostname
  }
}
