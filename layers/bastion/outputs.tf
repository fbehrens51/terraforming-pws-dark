output "bastion_ip" {
  value = element(
    concat(
      module.bootstrap.public_ips,
      [module.bootstrap.eni_ips[0]],
    ),
    0,
  )
}

output "bastion_private_ip" {
  value = module.bootstrap.eni_ips[0]
}

output "bastion_cidr_block" {
  value = data.aws_vpc.vpc.cidr_block
}

output "bot_user_on_bastion" {
  value = var.add_bot_user_to_user_data
}

output "bastion_route_table_id" {
  value = local.derived_route_table_id
}

output "ssh_host_ips" {
  value = zipmap(flatten(module.bastion_host.ssh_host_names), [element(concat(module.bootstrap.public_ips, [module.bootstrap.eni_ips[0]]), 0)])
}
