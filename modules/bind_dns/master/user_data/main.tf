variable "client_cidr" {
}

variable "slave_ips" {
  type = list(string)
}

variable "zone_name" {
}

variable "master_ip" {
}

variable "secret" {
}

module "bind_conf_content" {
  source      = "../conf"
  client_cidr = var.client_cidr
  master_ip   = var.master_ip
  secret      = var.secret
  slave_ips   = var.slave_ips
  zone_name   = var.zone_name
}

data "template_file" "user_data" {
  template = file("${path.module}/user_data.tpl")

  vars = {
    named_conf_content = base64encode(module.bind_conf_content.named_conf_content)
    zone_content       = base64encode(module.bind_conf_content.zone_content)
    zone_file_name     = "db.${var.zone_name}"
    reverse_content    = base64encode(module.bind_conf_content.reverse_content)
    rndc_content       = base64encode(module.bind_conf_content.rndc_key_content)
    reverse_file_name  = "db.${module.bind_conf_content.reverse_name}"
  }
}

output "user_data" {
  value     = data.template_file.user_data.rendered
  sensitive = true
}

