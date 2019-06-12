output "dn" {
  value = "${local.admin}"
}

output "basedn" {
  value = "${local.basedn}"
}

output "role_attr" {
  value = "role"
}

output "password" {
  value = "${random_string.ldap_password.result}"
}

output "ca_cert" {
  value = "${tls_self_signed_cert.user_pki_cert.cert_pem}"
}

output "client_cert" {
  value = "${tls_locally_signed_cert.client_cert.cert_pem}"
}

output "client_key" {
  value = "${tls_private_key.client_private_key.private_key_pem}"
}
