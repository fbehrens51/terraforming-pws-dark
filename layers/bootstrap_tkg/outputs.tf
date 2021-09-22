output "tkgjb_cidr_block" {
  value = local.tkgjb_cidr_block
}

output "tkg_subnet_cidrs" {
  value = [data.aws_vpc.vpc.cidr_block]
}

output "tkg_public_subnet_ids" {
  value = module.public_subnet.subnet_ids
}
