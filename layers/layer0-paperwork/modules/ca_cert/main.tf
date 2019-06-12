variable "env_name" {}

resource "tls_private_key" "root_private_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "tls_self_signed_cert" "root_cert" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.root_private_key.private_key_pem}"

  subject {
    common_name  = "${var.env_name} Root CA"
    organization = "${var.env_name}"
  }

  validity_period_hours = 8760 # 365 days

  early_renewal_hours = 4320 # 180 days

  allowed_uses = [
    "digital_signature",
    "server_auth",
    "client_auth",
    "cert_signing",
  ]

  is_ca_certificate = true
}

output "private_key_pem" {
  value = "${tls_private_key.root_private_key.private_key_pem}"
}

output "cert_pem" {
  value = "${tls_self_signed_cert.root_cert.cert_pem}"
}
