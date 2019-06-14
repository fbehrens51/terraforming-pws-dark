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
  value     = "${random_string.ldap_password.result}"
  sensitive = true
}
