
# Trusted issuer for all user certs

resource "tls_private_key" "issuer" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "issuer" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.issuer.private_key_pem

  subject {
    common_name  = "User PKI Root"
    organization = "VMware Tanzu Web Services"
  }
}

resource "tls_locally_signed_cert" "issuer" {
  cert_request_pem   = tls_cert_request.issuer.cert_request_pem
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = tls_private_key.root.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root.cert_pem

  allowed_uses = [
    "digital_signature",
    "cert_signing",
  ]

  is_ca_certificate = true

  validity_period_hours = 8760 # 365 days

  early_renewal_hours = 4320 # 180 days
}

# User certificates

resource "tls_private_key" "user" {
  count     = length(var.users)
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "user" {
  count           = length(var.users)
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.user[count.index].private_key_pem

  subject {
    common_name         = var.users[count.index].common_name
    organization        = "VMware Tanzu Web Services"
    organizational_unit = var.users[count.index].ou
  }
}

resource "tls_locally_signed_cert" "user" {
  count              = length(var.users)
  cert_request_pem   = tls_cert_request.user[count.index].cert_request_pem
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = tls_private_key.issuer.private_key_pem
  ca_cert_pem        = tls_locally_signed_cert.issuer.cert_pem

  allowed_uses = [
    "digital_signature",
    "client_auth",
  ]

  validity_period_hours = 8760 # 365 days

  early_renewal_hours = 4320 # 180 days
}

output "user_ldifs" {
  value = templatefile("${path.module}/users.ldif.tpl", {
    users = var.users,
  })
}
