resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm     = "RSA"
  private_key_pem   = tls_private_key.ca.private_key_pem
  is_ca_certificate = true

  subject {
    common_name  = "${var.prefix} CA"
    organization = "H2O.ai"
  }

  validity_period_hours = 87600

  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]
}

resource "kubernetes_secret" "ca" {
  metadata {
    name = "${var.prefix}-ca"
  }

  data = {
    certificate = tls_self_signed_cert.ca.cert_pem
  }
}

resource "tls_private_key" "server" {
  for_each = toset(var.tls_servers)

  algorithm = "RSA"
  rsa_bits  = "4096"
}


resource "tls_cert_request" "server" {
  for_each = toset(var.tls_servers)

  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.server[each.key].private_key_pem

  dns_names    = ["localhost", "${var.prefix}-${each.key}", "${var.prefix}-${each.key}.${var.namespace}"]
  ip_addresses = ["127.0.0.1"]

  subject {
    common_name  = "${var.prefix}-${each.key} Server"
    organization = "H2O.ai"
  }
}

resource "tls_locally_signed_cert" "server" {
  for_each = toset(var.tls_servers)

  cert_request_pem   = tls_cert_request.server[each.key].cert_request_pem
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = var.tls_validity_period_hours

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
}

resource "kubernetes_secret" "tls_server" {
  for_each = toset(var.tls_servers)

  metadata {
    name = "${var.prefix}-${each.key}-tls-server"
  }

  data = {
    certificate = tls_locally_signed_cert.server[each.key].cert_pem
    key         = tls_private_key.server[each.key].private_key_pem
  }
}

resource "tls_private_key" "client" {
  for_each = var.tls_clients

  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "tls_cert_request" "client" {
  for_each = var.tls_clients

  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.client[each.key].private_key_pem

  dns_names    = ["localhost", "${var.prefix}-${each.key}", "${var.prefix}-${each.key}.${var.namespace}"]
  ip_addresses = ["127.0.0.1"]
  uris         = each.value.spiffe ? ["spiffe://${var.spiffe_trust_domain}/${each.key}"] : null

  subject {
    common_name  = "${var.prefix}-${each.key} Client"
    organization = "H2O.ai"
  }
}

resource "tls_locally_signed_cert" "client" {
  for_each = var.tls_clients

  cert_request_pem   = tls_cert_request.client[each.key].cert_request_pem
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = var.tls_validity_period_hours

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "client_auth",
  ]
}

resource "kubernetes_secret" "tls_client" {
  for_each = var.tls_clients

  metadata {
    name = "${var.prefix}-${each.key}-tls-client"
  }

  data = {
    certificate = tls_locally_signed_cert.client[each.key].cert_pem
    key         = tls_private_key.client[each.key].private_key_pem
  }
}
