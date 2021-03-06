variable "availability_zones" {
  type = list(string)
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
}

variable "metrics_config" {
}

variable "metrics_store_config" {
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

locals {
  metrics_template = templatefile("${path.module}/metrics_config.tpl", {
    scale                       = var.scale["appMetrics"]
    bosh_network_name           = var.bosh_network_name
    pas_vpc_azs                 = join("", data.template_file.pas_vpc_azs.*.rendered)
    singleton_availability_zone = var.singleton_availability_zone
    syslog_host                 = var.syslog_host
    syslog_port                 = var.syslog_port
    syslog_ca_cert              = var.syslog_ca_cert
  })
}

locals {
  metrics_store_template = templatefile("${path.module}/metrics_store_config.tpl", {
    scale                       = var.scale["metric-store"]
    bosh_network_name           = var.bosh_network_name
    pas_vpc_azs                 = join("", data.template_file.pas_vpc_azs.*.rendered)
    singleton_availability_zone = var.singleton_availability_zone
    syslog_host                 = var.syslog_host
    syslog_port                 = var.syslog_port
    syslog_ca_cert              = var.syslog_ca_cert
  })
}

resource "aws_s3_bucket_object" "metrics_template" {
  bucket  = var.secrets_bucket_name
  key     = var.metrics_config
  content = local.metrics_template
}

resource "aws_s3_bucket_object" "metrics_store_template" {
  bucket  = var.secrets_bucket_name
  key     = var.metrics_store_config
  content = local.metrics_store_template
}
