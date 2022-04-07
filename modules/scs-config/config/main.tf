variable "availability_zones" {
  type = list(string)
}

variable "network_name" {
}

variable "scale" {
  type = map(map(string))
}

variable "scs_config" {
}

variable "secrets_bucket_name" {
}

variable "singleton_availability_zone" {
}

variable "syslog_ca_cert" {
}

variable "syslog_host" {
}

variable "syslog_port" {
}

locals {
  scs_config = templatefile("${path.module}/scs_config.tpl", {
    network_name                = var.network_name
    scale                       = var.scale["p-scs"]
    singleton_availability_zone = var.singleton_availability_zone
    az_yaml                     = format("%#v", flatten([for zone in var.availability_zones : { "name" = zone }]))
    syslog_host                 = var.syslog_host
    syslog_port                 = var.syslog_port
    syslog_ca_cert              = var.syslog_ca_cert
  })
}

resource "aws_s3_bucket_object" "scs_template" {
  bucket  = var.secrets_bucket_name
  key     = var.scs_config
  content = local.scs_config
}
