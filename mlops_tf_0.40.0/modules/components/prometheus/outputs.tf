output internal_url {
  value = "http://${local.prometheus_server_name}:${local.prometheus_server_port}"
}
