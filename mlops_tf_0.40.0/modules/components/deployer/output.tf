output "service" {
  value = {
    name                   = local.deployer_name
    port                   = local.deployer_port
    node_port              = kubernetes_service.deployer.spec[0].port[0].node_port
    load_balancer_ip       = coalescelist(kubernetes_service.deployer.load_balancer_ingress, [{ ip : null }])[0].ip
    load_balancer_hostname = coalescelist(kubernetes_service.deployer.load_balancer_ingress, [{ hostname : null }])[0].hostname
  }
}
