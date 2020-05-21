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

variable "splunk_syslog_ca_cert" {
}

variable "bosh_network_name" {
}

variable "secrets_bucket_name" {
}

variable "metrics_config" {
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

data "template_file" "metrics_template" {
  template = file("${path.module}/metrics_config.tpl")

  vars = {
    bosh_network_name           = var.bosh_network_name
    pas_vpc_azs                 = indent(4, join("", data.template_file.pas_vpc_azs.*.rendered))
    singleton_availability_zone = var.singleton_availability_zone
    syslog_host          = var.syslog_host
    syslog_port          = var.syslog_port
    splunk_syslog_ca_cert       = var.splunk_syslog_ca_cert
  }
}

resource "aws_s3_bucket_object" "metrics_template" {
  bucket  = var.secrets_bucket_name
  key     = var.metrics_config
  content = data.template_file.metrics_template.rendered
}
