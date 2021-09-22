
output "control_plane_public_cidrs" {
  value = module.public_subnets.subnet_cidr_blocks
}

output "control_plane_subnet_cidrs" {
  value = [data.aws_vpc.vpc.cidr_block]
}

output "control_plane_private_subnet_cidrs" {
  value = module.private_subnets.subnet_cidr_blocks
}

output "control_plane_subnet_availability_zones" {
  value = var.availability_zones
}

output "control_plane_subnet_gateways" {
  value = module.private_subnets.subnet_gateways
}

output "control_plane_subnet_ids" {
  value = module.private_subnets.subnet_ids
}

output "vms_security_group_id" {
  value = aws_security_group.vms_security_group[0].id
}

output "private_cidr_block" {
  value = local.private_cidr_block
}
output "sjb_cidr_block" {
  value = local.sjb_cidr_block
}

output "tkgjb_cidr_block" {
  value = local.tkgjb_cidr_block
}

output "terraform_region" {
  value = var.terraform_region
}

output "ec2_vpce_eni_ids" {
  value = aws_vpc_endpoint.cp_ec2.network_interface_ids
}

output "control_plane_public_subnet_ids" {
  value = module.public_subnets.subnet_ids
}

output "control_plane_rds_cidr_block" {
  value = local.rds_cidr_block
}
