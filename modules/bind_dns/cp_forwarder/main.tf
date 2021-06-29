variable "client_cidr" {
}

variable "master_ips" {
  type = list(string)
}

variable "forwarders" {
  type = list(object({
    domain        = string
    forwarder_ips = list(string)
  }))
}

module "bind_conf_content" {
  source      = "./conf"
  client_cidr = var.client_cidr
  forwarders  = var.forwarders
}

output "user_data" {
  value = templatefile("${path.module}/user_data.tpl", {
    named_conf_content = base64encode(module.bind_conf_content.named_conf_content),
    remote_dns         = var.forwarders[index(var.forwarders.*.domain, "")].forwarder_ips
  })
  sensitive = true
}

