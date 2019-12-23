output "vpc_id" {
  value = data.aws_vpc.vpc.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnets.*.id
}

output "zone_id" {
  value = local.zone_id
}

output "name_servers" {
  value = formatlist("%s.", compact(split(",", local.name_servers)))
}

output "vms_security_group_id" {
  value = element(concat(aws_security_group.vms_security_group.*.id, [""]), 0)
}

output "public_subnet_availability_zones" {
  value = aws_subnet.public_subnets.*.availability_zone
}

output "public_subnet_cidrs" {
  value = aws_subnet.public_subnets.*.cidr_block
}

output "infrastructure_subnet_ids" {
  value = aws_subnet.infrastructure_subnets.*.id
}

output "infrastructure_subnets" {
  value = aws_subnet.infrastructure_subnets.*.id
}

output "infrastructure_subnet_availability_zones" {
  value = aws_subnet.infrastructure_subnets.*.availability_zone
}

output "infrastructure_subnet_cidrs" {
  value = aws_subnet.infrastructure_subnets.*.cidr_block
}

output "infrastructure_subnet_gateways" {
  value = data.template_file.infrastructure_subnet_gateways.*.rendered
}

