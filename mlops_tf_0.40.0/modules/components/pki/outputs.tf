output "ca_secret_name" {
  value = kubernetes_secret.ca.metadata[0].name
}

output "tls_client_secrets_names" {
  description = "Names of kubernetes secrets holding TLS client pairs."
  value = { for client_name in keys(var.tls_clients) :
    client_name => kubernetes_secret.tls_client[client_name].metadata[0].name
  }
}

output "tls_server_secrets_names" {
  description = "Names of kubernetes secrets holding TLS server pairs."
  value = { for server_name in var.tls_servers :
    server_name => kubernetes_secret.tls_server[server_name].metadata[0].name
  }
}
