output "password" {
  value = "${random_string.ldap_password.result}"
}
