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

output "ldap_server_cert" {
  value = "${module.ldap_server_cert.cert_pem}"
}

output "ldap_server_key" {
  value = "${module.ldap_server_cert.private_key_pem}"
}
