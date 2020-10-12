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
