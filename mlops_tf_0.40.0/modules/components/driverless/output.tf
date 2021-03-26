# output "services" {
#   value = [for driverless in kubernetes_service.driverless : {
#     port                   = local.driverless_port
#     node_port              = driverless.spec[0].port[0].node_port
#     load_balancer_ip       = coalescelist(driverless.load_balancer_ingress, [{ ip : null }])[0].ip
#     load_balancer_hostname = coalescelist(driverless.load_balancer_ingress, [{ hostname : null }])[0].hostname
#   }]
# }

# output "ingresses" {
#   value = [for driverless in kubernetes_ingress.driverless : {
#     name = driverless.metadata[0].name
#     host = driverless.spec[0].rule[0].host
#   }]
# }

output "license_secret_name" {
  value = local.license_secret_name
}
