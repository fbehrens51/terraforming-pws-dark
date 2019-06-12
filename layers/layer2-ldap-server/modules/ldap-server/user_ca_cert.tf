resource "tls_private_key" "user_pki_root_private_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "tls_self_signed_cert" "user_pki_cert" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.user_pki_root_private_key.private_key_pem}"

  subject {
    common_name  = "${var.domain}"
    organization = "${var.env_name} User PKI Root"
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

# This is the cert used by portal to connect to LDAP as a client
resource "tls_private_key" "client_private_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "tls_cert_request" "client_cert_request" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.client_private_key.private_key_pem}"

  subject {
    common_name  = "LDAP Client"
    organization = "${var.env_name} Client"
  }
}

resource "tls_locally_signed_cert" "client_cert" {
  cert_request_pem   = "${tls_cert_request.client_cert_request.cert_request_pem}"
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = "${tls_private_key.user_pki_root_private_key.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.user_pki_cert.cert_pem}"

  allowed_uses = [
    "digital_signature",
    "server_auth",
    "client_auth",
  ]

  validity_period_hours = 8760 # 365 days

  early_renewal_hours = 4320 # 180 days
}
