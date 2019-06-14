output "bastion_public_vpc_route_table_id" {
  value = "${module.vpc_route_tables.bastion_public_vpc_route_table_id}"
}

output "cp_public_vpc_route_table_id" {
  value = "${module.vpc_route_tables.cp_public_vpc_route_table_id}"
}

output "es_public_vpc_route_table_id" {
  value = "${module.vpc_route_tables.es_public_vpc_route_table_id}"
}

output "pas_public_vpc_route_table_id" {
  value = "${module.vpc_route_tables.pas_public_vpc_route_table_id}"
}

output "es_public_vpc_route_table_id" {
  value = "${module.vpc_route_tables.es_public_vpc_route_table_id}"
}

output "pas_private_vpc_route_table_id" {
  value = "${module.vpc_route_tables.pas_private_vpc_route_table_id}"
}
