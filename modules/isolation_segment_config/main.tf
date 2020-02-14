variable "iso_seg_name" {
}

variable "iso_seg_tile_suffix" {
}


variable "vanity_cert_enabled" {
}

variable "vanity_cert_pem" {
}

variable "vanity_private_key_pem" {
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

data "aws_subnet" "isolation_segment_subnets" {
  count = length(var.pas_subnet_availability_zones)

  availability_zone = var.pas_subnet_availability_zones[count.index]

  tags = {
    isolation_segment = var.iso_seg_name
  }
}


data "template_file" "tile_config" {
  template = file("${path.module}/isolation_segment_template.tpl")

  vars = {
    vpc_id                         = data.aws_subnet.isolation_segment_subnets[0].vpc_id
    iso_seg_tile_suffix            = var.iso_seg_tile_suffix
    iso_seg_tile_suffix_underscore = replace(var.iso_seg_tile_suffix, "-", "_")
    vanity_cert_pem                = var.vanity_cert_pem
    vanity_private_key_pem         = var.vanity_private_key_pem
    vanity_cert_enabled            = var.vanity_cert_enabled
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

output "tile_config" {
  value = data.template_file.tile_config.rendered
}

