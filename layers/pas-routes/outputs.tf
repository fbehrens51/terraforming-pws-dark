output "pas_public_vpc_route_table_id" {
  value = module.pas_vpc_route_tables.public_route_table_id
}

output "pas_private_vpc_route_table_ids" {
  value = module.pas_vpc_route_tables.private_route_table_ids
}
