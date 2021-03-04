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

variable "syslog_host" {
}

variable "syslog_port" {
}

variable "syslog_ca_cert" {
}

variable "custom_ssh_banner" {
}

variable "secrets_bucket_name" {
  type = string
}

variable "compliance_scanner_config" {
}

variable "reports_bucket_name" {
}

variable "reports_bucket_region" {
}

variable "scale" {
  type = map(map(string))
}

locals{
  compliance_scanner_config = templatefile("${path.module}/compliance_scanner_config.tpl", {
    scale = var.scale["p-compliance-scanner"]
    network_name = var.network_name
    //availability_zones value isn't being used to configure AZs, so hard coding to use singleton_az for now
    //availability_zones = "[${join(",", var.availability_zones)}]"
    availability_zones          = var.singleton_availability_zone
    singleton_availability_zone = var.singleton_availability_zone
    ntp_servers                 = join(",", var.ntp_servers)
    syslog_host                 = var.syslog_host
    syslog_port                 = var.syslog_port
    syslog_ca_cert              = var.syslog_ca_cert
    custom_ssh_banner           = var.custom_ssh_banner
    reports_bucket_name         = var.reports_bucket_name
    reports_bucket_region       = var.reports_bucket_region
  })
}

resource "aws_s3_bucket_object" "compliance_scanner_template" {
  bucket  = var.secrets_bucket_name
  key     = var.compliance_scanner_config
  content = local.compliance_scanner_config
}
