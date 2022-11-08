variable "availability_zones" {
  type = list(string)
}

variable "network_name" {
}

variable "scale" {
  type = map(map(string))
}

variable "spring_gateway_config" {
}

variable "java_buildpack" {
  type = string
  default = "java_buildpack_offline"
  description = "java buildback for the service instance to use"
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
  spring_gateway_config = templatefile("${path.module}/gateway_tile_config.tpl", {
    network_name                = var.network_name
    scale                       = var.scale["p-spring-gateway"]
    singleton_availability_zone = var.singleton_availability_zone
    az_yaml                     = format("%#v", flatten([for zone in var.availability_zones : { "name" = zone }]))
    syslog_host                 = var.syslog_host
    syslog_port                 = var.syslog_port
    syslog_ca_cert              = var.syslog_ca_cert
    java_buildpack              = var.java_buildpack
  })
}

resource "aws_s3_bucket_object" "spring_gateway_template" {
  bucket  = var.secrets_bucket_name
  key     = var.spring_gateway_config
  content = local.spring_gateway_config
}