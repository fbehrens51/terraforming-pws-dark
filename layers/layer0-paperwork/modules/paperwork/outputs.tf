output "pas_vpc_id" {
  value = "${aws_vpc.pas_vpc.id}"
}

output "bastion_vpc_id" {
  value = "${aws_vpc.bastion_vpc.id}"
}

output "es_vpc_id" {
  value = "${aws_vpc.enterprise_services_vpc.id}"
}

output "cp_vpc_id" {
  value = "${aws_vpc.control_plane_vpc.id}"
}

output "root_ca_cert" {
  value = "${module.ca_cert.cert_pem}"
}

# This output is duplicated here to allow operators to override the value on-site without changing consumers
# (on-site it is not the same value for both router_trusted_ca_certs and trusted_ca_certs)
output "router_trusted_ca_certs" {
  value = "${module.ca_cert.cert_pem}"
}

# This output is duplicated here to allow operators to override the value on-site without changing consumers
# (on-site it is not the same value for both router_trusted_ca_certs and trusted_ca_certs)
output "trusted_ca_certs" {
  value = "${module.ca_cert.cert_pem}"
}

output "ldap_server_cert" {
  value = "${module.ldap_server_cert.cert_pem}"
}

output "ldap_server_key" {
  value     = "${module.ldap_server_cert.private_key_pem}"
  sensitive = true
}

output "router_server_cert" {
  value = "${module.router_server_cert.cert_pem}"
}

output "router_server_key" {
  value     = "${module.router_server_cert.private_key_pem}"
  sensitive = true
}

output "uaa_server_cert" {
  value = "${module.uaa_server_cert.cert_pem}"
}

output "uaa_server_key" {
  value     = "${module.uaa_server_cert.private_key_pem}"
  sensitive = true
}

output "ldap_client_cert" {
  value = "${module.ldap_client_cert.cert_pem}"
}

output "ldap_client_key" {
  value     = "${module.ldap_client_cert.private_key_pem}"
  sensitive = true
}

output "user_certs" {
  value = "${zipmap(data.template_file.usernames.*.rendered, tls_locally_signed_cert.user_pki_cert.*.cert_pem)}"
}

output "user_private_keys" {
  value     = "${zipmap(data.template_file.usernames.*.rendered, tls_private_key.user_pki_cert_private_key.*.private_key_pem)}"
  sensitive = true
}

data "template_file" "usernames" {
  count    = "${length(var.users)}"
  template = "${lookup(var.users[count.index], "username")}"
}
