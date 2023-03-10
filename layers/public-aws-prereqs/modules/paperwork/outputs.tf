output "pas_vpc_id" {
  value = aws_vpc.pas_vpc.id
}

output "bastion_vpc_id" {
  value = aws_vpc.bastion_vpc.id
}

output "es_vpc_id" {
  value = aws_vpc.enterprise_services_vpc.id
}

output "cp_vpc_id" {
  value = aws_vpc.control_plane_vpc.id
}

output "root_ca_cert" {
  value = module.ca_cert.cert_pem
}

output "control_plane_star_server_cert" {
  value = module.control_plane_star_server_cert.cert_pem
}

output "control_plane_star_server_key" {
  value     = module.control_plane_star_server_cert.private_key_pem
  sensitive = true
}

output "om_server_cert" {
  value = module.om_server_cert.cert_pem
}

output "om_server_key" {
  value     = module.om_server_cert.private_key_pem
  sensitive = true
}

output "fluentd_server_cert" {
  value = module.fluentd_server_cert.cert_pem
}

output "fluentd_server_key" {
  value     = module.fluentd_server_cert.private_key_pem
  sensitive = true
}

output "loki_server_cert" {
  value = module.loki_server_cert.cert_pem
}

output "loki_server_key" {
  value     = module.loki_server_cert.private_key_pem
  sensitive = true
}

output "smtp_server_cert" {
  value = module.smtp_server_cert.cert_pem
}

output "smtp_server_key" {
  value     = module.smtp_server_cert.private_key_pem
  sensitive = true
}

output "grafana_server_cert" {
  value = module.grafana_server_cert.cert_pem
}

output "grafana_server_key" {
  value     = module.grafana_server_cert.private_key_pem
  sensitive = true
}

output "router_server_cert" {
  value = module.router_server_cert.cert_pem
}

output "router_server_key" {
  value     = module.router_server_cert.private_key_pem
  sensitive = true
}

output "uaa_server_cert" {
  value = module.uaa_server_cert.cert_pem
}

output "uaa_server_key" {
  value     = module.uaa_server_cert.private_key_pem
  sensitive = true
}

output "ldap_client_cert" {
  value = module.ldap_client_cert.cert_pem
}

output "ldap_client_key" {
  value     = module.ldap_client_cert.private_key_pem
  sensitive = true
}

output "loki_client_cert" {
  value = module.loki_client_cert.cert_pem
}

output "loki_client_key" {
  value     = module.loki_client_cert.private_key_pem
  sensitive = true
}

output "vanity_server_cert" {
  value = module.vanity_server_cert.cert_pem
}

output "vanity_server_key" {
  value     = module.vanity_server_cert.private_key_pem
  sensitive = true
}

output "vanity2_server_cert" {
  value = module.vanity2_server_cert.cert_pem
}

output "vanity2_server_key" {
  value     = module.vanity2_server_cert.private_key_pem
  sensitive = true
}
output "isolation_segment_vpc_1_id" {
  value = aws_vpc.isolation_segment_vpc.id
}
