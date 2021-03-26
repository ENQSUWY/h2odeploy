output "service" {
  value = {
    host = local.rabbitmq_name
    port = local.tcp_port
  }
}

output "rabbitmq_drift_secret_name" {
  value = kubernetes_secret.rabbitmq_drift_env.metadata[0].name
}
