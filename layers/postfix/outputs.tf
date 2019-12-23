output "postfix_ssh_private_key" {
  value     = module.postfix_host_key_pair.private_key_pem
  sensitive = true
}

output "postfix_ip" {
  value = local.postfix_ip
}

variable "client_cidr" {
}

