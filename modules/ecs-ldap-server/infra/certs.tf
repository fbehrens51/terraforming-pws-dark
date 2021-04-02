
resource "aws_acm_certificate" "ldap" {
  private_key       = tls_private_key.ldap.private_key_pem
  certificate_body  = tls_locally_signed_cert.ldap.cert_pem
  certificate_chain = tls_self_signed_cert.root.cert_pem
}

resource "tls_private_key" "root" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_self_signed_cert" "root" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.root.private_key_pem

  subject {
    common_name  = "pcfeagle.cf-app.com"
    organization = "VMware Tanzu Web Services Root"
  }

  validity_period_hours = 8760 # 365 days

  early_renewal_hours = 4320 # 180 days

  allowed_uses = [
    "digital_signature",
    "cert_signing",
  ]

  is_ca_certificate = true
}

resource "tls_private_key" "ldap" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "ldap" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.ldap.private_key_pem

  subject {
    common_name  = "ldap.pcfeagle.cf-app.com"
    organization = "VMware Tanzu Web Services LDAP"
  }

  dns_names = [aws_lb.ldap.dns_name]
}

resource "tls_locally_signed_cert" "ldap" {
  cert_request_pem   = tls_cert_request.ldap.cert_request_pem
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = tls_private_key.root.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root.cert_pem

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]

  validity_period_hours = 8760 # 365 days

  early_renewal_hours = 4320 # 180 days
}
