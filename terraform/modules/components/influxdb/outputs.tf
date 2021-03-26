output internal_url {
  value = "http://${local.influxdb_name}:${local.http_port}"
}

output "service" {
  value = {
    host = local.influxdb_name
    port = local.http_port
  }
}
