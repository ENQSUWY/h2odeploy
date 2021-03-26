output "service" {
  value = {
    name = local.ingestion_name
    port = local.ingestion_port
  }
}
