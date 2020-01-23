locals {
  isolation_segment_product_version = "2.7.8"
  isolation_segment_file_version    = "2.7.8-build.6"
}

variable "pivnet_api_token" {
}

variable "iso_seg_tile_suffix" {
}

variable "s3_access_key_id" {
}

variable "s3_secret_access_key" {
}

variable "s3_auth_type" {
}

variable "s3_endpoint" {
}

variable "region" {
}

variable "mirror_bucket" {
}

variable "router_cert_pem" {
}

variable "router_private_key_pem" {
}

variable "router_trusted_ca_certificates" {
}

variable "splunk_syslog_host" {
}

variable "splunk_syslog_port" {
}

variable "splunk_syslog_ca_cert" {
}

variable "pas_subnet_availability_zones" {
  type = list(string)
}

variable "singleton_availability_zone" {
  type = string
}

data "template_file" "pas_vpc_azs" {
  count = length(var.pas_subnet_availability_zones)

  template = <<EOF
- name: $${pas_subnet_availability_zone}
EOF


  vars = {
    pas_subnet_availability_zone = var.pas_subnet_availability_zones[count.index]
  }
}

data "template_file" "download_config" {
  template = file("${path.module}/download_product_config.tpl")

  vars = {
    pivnet_api_token     = var.pivnet_api_token
    pivnet_file_glob     = "*.pivotal"
    pivnet_product_slug  = "p-isolation-segment-${var.iso_seg_tile_suffix}"
    product_version      = local.isolation_segment_product_version
    s3_endpoint          = var.s3_endpoint
    s3_region_name       = var.region
    s3_access_key_id     = var.s3_access_key_id
    s3_secret_access_key = var.s3_secret_access_key
    s3_auth_type         = var.s3_auth_type
    s3_bucket            = var.mirror_bucket
  }
}

data "template_file" "base_tile_download_config" {
  template = file("${path.module}/download_product_config.tpl")

  vars = {
    pivnet_api_token     = var.pivnet_api_token
    pivnet_file_glob     = "*.pivotal"
    pivnet_product_slug  = "p-isolation-segment"
    product_version      = local.isolation_segment_product_version
    s3_endpoint          = var.s3_endpoint
    s3_region_name       = var.region
    s3_access_key_id     = var.s3_access_key_id
    s3_secret_access_key = var.s3_secret_access_key
    s3_auth_type         = var.s3_auth_type
    s3_bucket            = var.mirror_bucket
  }
}

data "template_file" "tile_config" {
  template = file("${path.module}/isolation_segment_template.tpl")

  vars = {
    iso_seg_tile_suffix            = var.iso_seg_tile_suffix
    iso_seg_tile_suffix_underscore = replace(var.iso_seg_tile_suffix, "-", "_")
    router_cert_pem                = var.router_cert_pem
    router_private_key_pem         = var.router_private_key_pem
    router_trusted_ca_certificates = var.router_trusted_ca_certificates
    splunk_syslog_host             = var.splunk_syslog_host
    splunk_syslog_port             = var.splunk_syslog_port
    splunk_syslog_ca_cert          = var.splunk_syslog_ca_cert
    pas_vpc_azs                    = indent(4, join("", data.template_file.pas_vpc_azs.*.rendered))
    singleton_availability_zone    = var.singleton_availability_zone
  }
}

output "product_version" {
  value = local.isolation_segment_product_version
}

output "file_version" {
  value = local.isolation_segment_file_version
}

output "base_tile_download_config" {
  value = data.template_file.base_tile_download_config.rendered
}

output "download_config" {
  value = data.template_file.download_config.rendered
}

output "tile_config" {
  value = data.template_file.tile_config.rendered
}

