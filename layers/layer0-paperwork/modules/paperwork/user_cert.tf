variable "users" {
  type = "list"
}

resource "tls_private_key" "user_pki_cert_private_key" {
  count     = "${length(var.users)}"
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "tls_cert_request" "user_pki_cert_request" {
  count           = "${length(var.users)}"
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.user_pki_cert_private_key.*.private_key_pem[count.index]}"

  subject {
    common_name  = "${lookup(var.users[count.index], "name")}"
    organization = "${var.env_name} User PKI"
  }
}

resource "tls_locally_signed_cert" "user_pki_cert" {
  count              = "${length(var.users)}"
  cert_request_pem   = "${tls_cert_request.user_pki_cert_request.*.cert_request_pem[ count.index ]}"
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = "${module.ca_cert.private_key_pem}"
  ca_cert_pem        = "${module.ca_cert.cert_pem}"

  allowed_uses = [
    "digital_signature",
    "server_auth",
    "client_auth",
  ]

  validity_period_hours = 8760 # 365 days

  early_renewal_hours = 4320 # 180 days
}
