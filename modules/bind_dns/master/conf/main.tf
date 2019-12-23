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

locals {
  slave_ips              = var.slave_ips
  flattened_transfer_ips = join("; ", local.slave_ips)
  slave_ip_1             = element(local.slave_ips, 1)
  slave_ip_2             = element(local.slave_ips, 2)
  last_master_octet      = element(split(".", var.master_ip), 3)
  last_slave1_octet      = element(split(".", local.slave_ip_1), 3)
  last_slave2_octet      = element(split(".", local.slave_ip_2), 3)

  reverse_name = format(
    "%s.%s.%s",
    element(split(".", var.master_ip), 2),
    element(split(".", var.master_ip), 1),
    element(split(".", var.master_ip), 0),
  )
}

data "template_file" "named_conf_content" {
  template = file("${path.module}/named.conf.tpl")

  vars = {
    client_cidr               = var.client_cidr
    allow_transfer_ips_string = local.flattened_transfer_ips
    zone_name                 = var.zone_name
    reverse_cidr_prefix       = local.reverse_name
  }
}

data "template_file" "zone_content" {
  template = file("${path.module}/db.zone.tpl")

  vars = {
    zone_name  = var.zone_name
    master_ip  = var.master_ip
    slave_ip_1 = local.slave_ip_1
    slave_ip_2 = local.slave_ip_2
  }
}

data "template_file" "reverse_content" {
  template = file("${path.module}/db.reverse.tpl")

  vars = {
    zone_name         = var.zone_name
    master_ip         = var.master_ip
    slave_ip_1        = local.slave_ip_1
    slave_ip_2        = local.slave_ip_2
    last_master_octet = local.last_master_octet
    last_slave1_octet = local.last_slave1_octet
    last_slave2_octet = local.last_slave2_octet
  }
}

data "template_file" "rndc_key_content" {
  template = file("${path.module}/rndc.key.tpl")

  vars = {
    secret = var.secret
  }
}

output "named_conf_content" {
  value = data.template_file.named_conf_content.rendered
}

output "zone_content" {
  value = data.template_file.zone_content.rendered
}

output "reverse_content" {
  value = data.template_file.reverse_content.rendered
}

output "rndc_key_content" {
  value     = data.template_file.rndc_key_content.rendered
  sensitive = true
}

output "reverse_name" {
  value = local.reverse_name
}

