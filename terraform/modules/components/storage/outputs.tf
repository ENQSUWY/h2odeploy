output "service" {
  value = {
    name = local.storage_name
    port = local.storage_port
  }
}
