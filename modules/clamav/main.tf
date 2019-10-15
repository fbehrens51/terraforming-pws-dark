variable "clamav_cpu_limit" {}
variable "clamav_enable_on_access_scanning" {}

variable "clamav_no_upstream_mirror" {}

variable "clamav_external_mirrors" {
  type = "list"
}

variable "availability_zones" {
  type = "list"
}

variable "clamav_mirror_instance_type" {}

variable "pivnet_api_token" {}
variable "product_blobs_s3_bucket" {}
variable "product_blobs_s3_endpoint" {}
variable "product_blobs_s3_region" {}
variable "s3_access_key_id" {}
variable "s3_secret_access_key" {}
variable "s3_auth_type" {}

variable "singleton_availability_zone" {
  type = "string"
}

variable "splunk_syslog_host" {}

variable "splunk_syslog_port" {}

variable "splunk_syslog_ca_cert" {}

variable "bosh_network_name" {}

locals {
  clamav_product_slug    = "p-clamav-addon"
  clamav_product_version = "2.0.12"

  clamav_addon_file_glob  = "p-clamav-[0-9]*.pivotal"
  clamav_mirror_file_glob = "p-clamav-mirror-[0-9]*.pivotal"
}

data "template_file" "pas_vpc_azs" {
  count = "${length(var.availability_zones)}"

  template = <<EOF
- name: $${availability_zone}
EOF

  vars = {
    availability_zone = "${var.availability_zones[count.index]}"
  }
}

data "template_file" "clamav_mirror_template" {
  template = "${file("${path.module}/clamav_mirror_template.tpl")}"

  vars = {
    bosh_network_name           = "${var.bosh_network_name}"
    external_mirrors            = "${join(",", var.clamav_external_mirrors)}"
    no_upstream_mirror          = "${var.clamav_no_upstream_mirror}"
    pas_vpc_azs                 = "${indent(4, join("", data.template_file.pas_vpc_azs.*.rendered))}"
    singleton_availability_zone = "${var.singleton_availability_zone}"
    clamav_mirror_instance_type = "${var.clamav_mirror_instance_type}"
    splunk_syslog_host          = "${var.splunk_syslog_host}"
    splunk_syslog_port          = "${var.splunk_syslog_port}"
    splunk_syslog_ca_cert       = "${var.splunk_syslog_ca_cert}"
  }
}

data "template_file" "clamav_addon_template" {
  template = "${file("${path.module}/clamav_addon_template.tpl")}"

  vars = {
    cpu_limit          = "${var.clamav_cpu_limit}"
    on_access_scanning = "${var.clamav_enable_on_access_scanning}"
  }
}

data "template_file" "download_clamav_mirror_config" {
  template = "${file("${path.module}/../ops_manager_config/download_product_config.tpl")}"

  vars = {
    pivnet_file_glob    = "${local.clamav_mirror_file_glob}"
    pivnet_product_slug = "${local.clamav_product_slug}"
    product_version     = "${local.clamav_product_version}"

    pivnet_api_token = "${var.pivnet_api_token}"
    s3_bucket        = "${var.product_blobs_s3_bucket}"

    s3_endpoint          = "${var.product_blobs_s3_endpoint}"
    s3_region_name       = "${var.product_blobs_s3_region}"
    s3_access_key_id     = "${var.s3_access_key_id}"
    s3_secret_access_key = "${var.s3_secret_access_key}"
    s3_auth_type         = "${var.s3_auth_type}"
  }
}

data "template_file" "download_clamav_addon_config" {
  template = "${file("${path.module}/../ops_manager_config/download_product_config.tpl")}"

  vars = {
    pivnet_file_glob    = "${local.clamav_addon_file_glob}"
    pivnet_product_slug = "${local.clamav_product_slug}"
    product_version     = "${local.clamav_product_version}"

    pivnet_api_token = "${var.pivnet_api_token}"
    s3_bucket        = "${var.product_blobs_s3_bucket}"

    s3_endpoint          = "${var.product_blobs_s3_endpoint}"
    s3_region_name       = "${var.product_blobs_s3_region}"
    s3_access_key_id     = "${var.s3_access_key_id}"
    s3_secret_access_key = "${var.s3_secret_access_key}"
    s3_auth_type         = "${var.s3_auth_type}"
  }
}

output "clamav_addon_template" {
  value     = "${data.template_file.clamav_addon_template.rendered}"
  sensitive = true
}

output "clamav_mirror_template" {
  value     = "${data.template_file.clamav_mirror_template.rendered}"
  sensitive = true
}

output "download_clamav_mirror_config" {
  value     = "${data.template_file.download_clamav_mirror_config.rendered}"
  sensitive = true
}

output "download_clamav_addon_config" {
  value     = "${data.template_file.download_clamav_addon_config.rendered}"
  sensitive = true
}
