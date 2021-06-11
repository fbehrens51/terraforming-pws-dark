variable "client_cidr" {
}

variable "forwarders" {
  type = list(object({
    domain        = string
    forwarder_ips = list(string)
  }))
}

output "named_conf_content" {
  value = templatefile("${path.module}/named.conf.tpl", {
    client_cidr = var.client_cidr
    forwarders  = var.forwarders
  })
}