output "internal_address" {
  value = "${local.postgres_name}:${local.postgres_port}"
}

output "storage_connection_string_secret_name" {
  value = kubernetes_secret.postgres_storage.metadata[0].name
}

output "storage_connection_string_key_name" {
  value = "go_pq_connection_string"
}
