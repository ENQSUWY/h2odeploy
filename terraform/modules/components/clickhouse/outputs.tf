output "service" {
  value = {
    name            = local.clickhouse_name
    http_port       = local.http_port
    https_port      = local.https_port
    tcp_port        = local.tcp_port
    tcp_port_secure = local.tcp_port_secure
  }
}

output "clickhouse_admin_secret_name" {
  value = kubernetes_secret.clickhouse_admin.metadata[0].name
}
