variable "clamav_cpu_limit" {
}

variable "clamav_enable_on_access_scanning" {
}

variable "clamav_no_upstream_mirror" {
}

variable "clamav_external_mirrors" {
  type = list(string)
}

variable "availability_zones" {
  type = list(string)
}

variable "s3_endpoint" {
}

variable "region" {
}

variable "singleton_availability_zone" {
  type = string
}

variable "syslog_host" {
}

variable "syslog_port" {
}

variable "syslog_ca_cert" {
}

variable "bosh_network_name" {
}

variable "secrets_bucket_name" {
  type = string
}

variable "clamav_addon_config" {
}

variable "clamav_mirror_config" {
}

variable "clamav_director_config" {
}

variable "clamav_release_url" {
}

variable "clamav_release_sha1" {
}

variable "scale" {
  type = map(map(string))
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

data "template_file" "clamav_director_template" {
  template = file("${path.module}/clamav_director_template.tpl")

  vars = {
    external_mirrors    = format("%#v", var.clamav_external_mirrors)
    cpu_limit           = var.clamav_cpu_limit
    on_access_scanning  = var.clamav_enable_on_access_scanning
    clamav_release_url  = var.clamav_release_url
    clamav_release_sha1 = var.clamav_release_sha1
  }
}

locals {
  clamav_mirror_template = templatefile("${path.module}/clamav_mirror_template.tpl", {
    scale                       = var.scale["p-antivirus-mirror"]
    bosh_network_name           = var.bosh_network_name
    external_mirrors            = join(",", var.clamav_external_mirrors)
    no_upstream_mirror          = var.clamav_no_upstream_mirror
    pas_vpc_azs                 = indent(4, join("", data.template_file.pas_vpc_azs.*.rendered))
    singleton_availability_zone = var.singleton_availability_zone
    syslog_host                 = var.syslog_host
    syslog_port                 = var.syslog_port
    syslog_ca_cert              = var.syslog_ca_cert
  })
}

data "template_file" "clamav_addon_template" {
  template = file("${path.module}/clamav_addon_template.tpl")

  vars = {
    cpu_limit          = var.clamav_cpu_limit
    on_access_scanning = var.clamav_enable_on_access_scanning
  }
}

resource "aws_s3_bucket_object" "clamav_addon_template" {
  bucket  = var.secrets_bucket_name
  key     = var.clamav_addon_config
  content = data.template_file.clamav_addon_template.rendered
}

resource "aws_s3_bucket_object" "clamav_mirror_template" {
  bucket  = var.secrets_bucket_name
  key     = var.clamav_mirror_config
  content = local.clamav_mirror_template
}

resource "aws_s3_bucket_object" "clamav_director_template" {
  bucket  = var.secrets_bucket_name
  key     = var.clamav_director_config
  content = data.template_file.clamav_director_template.rendered
}
