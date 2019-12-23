variable "availability_zones" {
  type = list(string)
}

variable "singleton_availability_zone" {
  type = string
}

variable "splunk_syslog_host" {
}

variable "splunk_syslog_port" {
}

variable "splunk_syslog_ca_cert" {
}

variable "bosh_network_name" {
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
    splunk_syslog_host          = var.splunk_syslog_host
    splunk_syslog_port          = var.splunk_syslog_port
    splunk_syslog_ca_cert       = var.splunk_syslog_ca_cert
  }
}

output "metrics_config" {
  value     = data.template_file.metrics_template.rendered
  sensitive = true
}

