variable "enterprise_dns" {
}

variable "forwarders" {
  type = list(object({
    domain        = string
    forwarder_ips = list(string)
  }))
}

output "dnsmasq_user_data" {
  value = templatefile("${path.module}/user_data.tpl", {
    enterprise_dns = var.enterprise_dns
    forwarders     = var.forwarders
  })
}
