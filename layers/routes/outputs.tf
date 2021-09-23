output "bastion_public_vpc_route_table_id" {
  value = module.bastion_vpc_route_tables.public_route_table_id
}

output "cp_private_vpc_route_table_ids" {
  value = module.cp_vpc_route_tables.private_route_table_ids
}

output "cp_public_vpc_route_table_id" {
  value = module.cp_vpc_route_tables.public_route_table_id
}

output "es_public_vpc_route_table_id" {
  value = module.es_vpc_route_tables.public_route_table_id
}

output "es_private_vpc_route_table_ids" {
  value = module.es_vpc_route_tables.private_route_table_ids
}

output "pas_public_vpc_route_table_id" {
  value = module.pas_vpc_route_tables.public_route_table_id
}

output "pas_private_vpc_route_table_ids" {
  value = module.pas_vpc_route_tables.private_route_table_ids
}

output "tkg_public_vpc_route_table_id" {
  value = var.enable_tkg ? module.tkg_vpc_route_tables[0].public_route_table_id : ""
}

output "tkg_private_vpc_route_table_ids" {
  value = var.enable_tkg ? module.tkg_vpc_route_tables[0].private_route_table_ids : []
}

