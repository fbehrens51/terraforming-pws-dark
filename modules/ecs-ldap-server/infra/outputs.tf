
output "ldap_basedn" {
  value = "dc=pcfeagle,dc=cf-app,dc=com"
}

output "ldap_dn" {
  value = "cn=admin,dc=pcfeagle,dc=cf-app,dc=com"
}

output "ldap_domain" {
  value = aws_lb.ldap.dns_name
}

output "ldap_port" {
  value = tostring(local.external_ldaps_port)
}

output "ldap_password" {
  value     = random_string.ldap_password.result
  sensitive = true
}

output "ldap_ca_cert" {
  value     = tls_self_signed_cert.root.cert_pem
  sensitive = true
}

output "user_ca_cert" {
  value = "${tls_self_signed_cert.root.cert_pem}\n${tls_locally_signed_cert.issuer.cert_pem}"
}

output "portal_smoke_test_cert" {
  value = {
    private_key_pem = tls_private_key.user["smoke_test"].private_key_pem
    cert_pem        = tls_locally_signed_cert.user["smoke_test"].cert_pem
  }
}

output "portal_end_to_end_test_user_cert" {
  value = {
    private_key_pem = tls_private_key.user["portal_test_people"].private_key_pem
    cert_pem        = tls_locally_signed_cert.user["portal_test_people"].cert_pem
  }
}

output "portal_end_to_end_test_application_cert" {
  value = {
    private_key_pem = tls_private_key.user["portal_test_apps_a"].private_key_pem
    cert_pem        = tls_locally_signed_cert.user["portal_test_apps_a"].cert_pem
  }
}

output "portal_end_to_end_test_application_cert_b" {
  value = {
    private_key_pem = tls_private_key.user["portal_test_apps_b"].private_key_pem
    cert_pem        = tls_locally_signed_cert.user["portal_test_apps_b"].cert_pem
  }
}

output "ecs_execution_role" {
  value = aws_iam_role.ldap.arn
}

output "ldap_password_secret" {
  value = aws_secretsmanager_secret.ldap_password.arn
}

output "ecs_cluster_id" {
  value = aws_ecs_cluster.eagle.id
}

output "ldap_security_group" {
  value = aws_security_group.ldap.id
}

output "ldap_target_group" {
  value = aws_lb_target_group.ldap.arn
}

output "private_subnets" {
  value = aws_subnet.private.*.id
}

