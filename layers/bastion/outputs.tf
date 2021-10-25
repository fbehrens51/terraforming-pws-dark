output "bastion_ip" {
  value = element(
    concat(
      module.bootstrap_bastion.public_ips,
      [module.bootstrap_bastion.private_ip],
    ),
    0,
  )
}

output "bastion_private_ip" {
  value = module.bootstrap_bastion.private_ip
}

output "bastion_cidr_block" {
  value = module.bootstrap_bastion.cidr_block
}

output "bot_user_on_bastion" {
  value = var.add_bot_user_to_user_data
}

output "bastion_route_table_id" {
  value = local.derived_route_table_id
}

output "ssh_host_ips" {
  value = zipmap(flatten(module.bastion_host.ssh_host_names), [element(concat(module.bootstrap_bastion.public_ips, [module.bootstrap_bastion.private_ip]), 0)])
}
