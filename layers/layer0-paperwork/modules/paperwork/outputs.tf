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
