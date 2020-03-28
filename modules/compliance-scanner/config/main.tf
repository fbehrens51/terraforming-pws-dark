variable "network_name" {
}

variable "availability_zones" {
  type = list(string)
}

variable "singleton_availability_zone" {
}

variable "ntp_servers" {
  type = list(string)
}

variable "splunk_syslog_host" {
}

variable "splunk_syslog_port" {
}

variable "splunk_syslog_ca_cert" {
}

variable "custom_ssh_banner" {
}

variable "secrets_bucket_name" {
  type = string
}

variable "compliance_scanner_config" {
}

data "template_file" "compliance_scanner_config" {
  template = file("${path.module}/compliance_scanner_config.tpl")

  vars = {
    network_name = var.network_name
    //availability_zones value isn't being used to configure AZs, so hard coding to use singleton_az for now
    //availability_zones = "[${join(",", var.availability_zones)}]"
    availability_zones          = var.singleton_availability_zone
    singleton_availability_zone = var.singleton_availability_zone
    ntp_servers                 = join(",", var.ntp_servers)
    splunk_syslog_host          = var.splunk_syslog_host
    splunk_syslog_port          = var.splunk_syslog_port
    splunk_syslog_ca_cert       = var.splunk_syslog_ca_cert
    custom_ssh_banner           = var.custom_ssh_banner
  }
}

resource "aws_s3_bucket_object" "compliance_scanner_template" {
  bucket  = var.secrets_bucket_name
  key     = var.compliance_scanner_config
  content = data.template_file.compliance_scanner_config.rendered
}
