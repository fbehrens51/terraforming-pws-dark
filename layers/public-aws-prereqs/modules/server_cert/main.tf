variable "ca_cert_pem" {
}

variable "ca_private_key_pem" {
}

variable "common_name" {
}

variable "env_name" {
}

variable "domains" {
  type    = list(string)
  default = []
}

variable "ips" {
  type    = list(string)
  default = []
}

resource "tls_private_key" "server_private_key" {
  count = 1

  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "tls_cert_request" "server_cert_request" {
  private_key_pem = tls_private_key.server_private_key[0].private_key_pem

  subject {
    common_name  = var.common_name
    organization = var.env_name
  }

  dns_names    = var.domains
  ip_addresses = var.ips
}

resource "tls_locally_signed_cert" "server_cert" {
  count = 1

  cert_request_pem   = tls_cert_request.server_cert_request.cert_request_pem
  ca_private_key_pem = var.ca_private_key_pem
  ca_cert_pem        = var.ca_cert_pem

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]

  validity_period_hours = 8760 # 365 days

  early_renewal_hours = 4320 # 180 days
}

output "private_key_pem" {
  value = element(
    concat(tls_private_key.server_private_key.*.private_key_pem, [""]),
    0,
  )
  sensitive = true
}

output "cert_pem" {
  value = element(
    concat(tls_locally_signed_cert.server_cert.*.cert_pem, [""]),
    0,
  )
}

