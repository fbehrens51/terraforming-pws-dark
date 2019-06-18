output "bastion_public_ip" {
  value = "${module.bootstrap_bastion.public_ips[0]}"
}

output "bastion_private_key" {
  value     = "${module.bastion_host_key_pair.private_key_pem}"
  sensitive = true
}

output "bastion_cidr_block" {
  value = "${module.bootstrap_bastion.cidr_block}"
}
