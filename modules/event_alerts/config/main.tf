variable "availability_zones" {
  type = list(string)
}

variable "singleton_availability_zone" {
  type = string
}

variable "bosh_network_name" {
  type = string
}

variable "pas_rds_cidr_block" {
  type = string
}

variable "mysql_host" {
  type = string
}

variable "mysql_port" {
  type = string
}

variable "mysql_username" {
  type = string
}

variable "mysql_password" {
  type = string
}

variable "mysql_name" {
  type = string
}

variable "mysql_ca_cert" {
  type = string
}

variable "mysql_use_tls" {
  type = string
}

variable "mysql_tls_skip_verify" {
  type = string
}

variable "smtp_host" {
  type = string
}

variable "smtp_username" {
  type = string
}

variable "smtp_password" {
  type = string
}

variable "smtp_port" {
  type = string
}

variable "smtp_from" {
  type = string
}

variable "smtp_tls_enabled" {
  type = string
}

variable "smtp_tls_skip_verify" {
  type = string
}

variable "smtp_enabled" {
  type = string
}

data "template_file" "pas_vpc_azs" {
  count = length(var.availability_zones)

  template = <<EOF
- name: $${availability_zone}
EOF

  vars = {
    availability_zone = var.availability_zones[count.index]
  }
}

data "template_file" "event_alerts_template" {
  template = file("${path.module}/event_alerts_config.tpl")

  vars = {
    bosh_network_name           = var.bosh_network_name
    pas_vpc_azs                 = indent(4, join("", data.template_file.pas_vpc_azs.*.rendered))
    singleton_availability_zone = var.singleton_availability_zone
    mysql_host                  = var.mysql_host
    mysql_port                  = var.mysql_port
    mysql_username              = var.mysql_username
    mysql_password              = var.mysql_password
    mysql_name                  = var.mysql_name
    mysql_ca_cert               = indent(6, var.mysql_ca_cert)
    mysql_use_tls               = var.mysql_use_tls
    mysql_tls_skip_verify       = var.mysql_tls_skip_verify
    smtp_enabled                = var.smtp_enabled
    smtp_host                   = var.smtp_host
    smtp_username               = var.smtp_username
    smtp_password               = var.smtp_password
    smtp_port                   = var.smtp_port
    smtp_from                   = var.smtp_from
    smtp_tls_enabled            = var.smtp_tls_enabled
    smtp_tls_skip_verify        = var.smtp_tls_skip_verify
  }
}

output "event_alerts_config" {
  value     = data.template_file.event_alerts_template.rendered
  sensitive = true
}

