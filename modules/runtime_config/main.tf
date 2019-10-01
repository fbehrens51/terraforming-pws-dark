variable "runtime_config_product_version" {}

variable "ipsec_log_level" {}
variable "ipsec_optional" {}

variable "ipsec_subnet_cidrs" {
  type = "list"
}

variable "no_ipsec_subnet_cidrs" {
  type = "list"
}

variable "custom_ssh_banner" {
  type        = "string"
  description = "Custom SSH Banner to be used on launched VMs"
}

variable "pivnet_api_token" {}
variable "product_blobs_s3_bucket" {}
variable "product_blobs_s3_endpoint" {}
variable "product_blobs_s3_region" {}
variable "s3_access_key_id" {}
variable "s3_secret_access_key" {}
variable "s3_auth_type" {}
variable "vpc_dns" {}

locals {
  runtime_config_file_glob    = "pws-dark-runtime-config*.pivotal"
  runtime_config_product_slug = "pws-dark-runtime-config-tile"
  vpc_dns_subnet              = "${var.vpc_dns}/32"
}

data "template_file" "runtime_config_template" {
  template = "${file("${path.module}/runtime_config_template.tpl")}"

  vars = {
    ipsec_log_level       = "${var.ipsec_log_level}"
    ipsec_optional        = "${var.ipsec_optional}"
    ipsec_subnet_cidrs    = "${join(",",  var.ipsec_subnet_cidrs)}"
    no_ipsec_subnet_cidrs = "${join(",", concat(var.no_ipsec_subnet_cidrs, list(local.vpc_dns_subnet)))}"
    ssh_banner            = "${var.custom_ssh_banner}"
  }
}

data "template_file" "download_runtime_config_config" {
  template = "${file("${path.module}/../ops_manager_config/download_product_config.tpl")}"

  vars = {
    pivnet_file_glob    = "${local.runtime_config_file_glob}"
    pivnet_product_slug = "${local.runtime_config_product_slug}"
    product_version     = "${var.runtime_config_product_version}"

    pivnet_api_token = "${var.pivnet_api_token}"
    s3_bucket        = "${var.product_blobs_s3_bucket}"

    s3_endpoint          = "${var.product_blobs_s3_endpoint}"
    s3_region_name       = "${var.product_blobs_s3_region}"
    s3_access_key_id     = "${var.s3_access_key_id}"
    s3_secret_access_key = "${var.s3_secret_access_key}"
    s3_auth_type         = "${var.s3_auth_type}"
  }
}

output "download_runtime_config_config" {
  value     = "${data.template_file.download_runtime_config_config.rendered}"
  sensitive = true
}

output "runtime_config_template" {
  value     = "${data.template_file.runtime_config_template.rendered}"
  sensitive = true
}
