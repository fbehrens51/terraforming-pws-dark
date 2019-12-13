variable "remote_state_bucket" {}
variable "remote_state_region" {}

//from global vars
variable "availability_zones" {
  type = "list"
}

variable "singleton_availability_zone" {}

variable "network_name" {}

variable "ntp_servers" {
  type = "list"
}

terraform {
  backend "s3" {}
}

data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "paperwork"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_splunk" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "bootstrap_splunk"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

module "domains" {
  source = "../../modules/domains"

  root_domain = "${local.root_domain}"
}

module "splunk_ports" {
  source = "../../modules/splunk_ports"
}

locals {
  root_domain = "${data.terraform_remote_state.paperwork.root_domain}"
}

module "compliance_scanner_config" {
  source                      = "../../modules/compliance-scanner/config"
  network_name                = "${var.network_name}"
  availability_zones          = "${var.availability_zones}"
  singleton_availability_zone = "${var.singleton_availability_zone}"
  ntp_servers                 = "${var.ntp_servers}"
  splunk_syslog_host          = "${module.domains.splunk_logs_fqdn}"
  splunk_syslog_port          = "${module.splunk_ports.splunk_tcp_port}"
  splunk_syslog_ca_cert       = "${data.terraform_remote_state.paperwork.trusted_ca_certs}"
  custom_ssh_banner           = "${data.terraform_remote_state.paperwork.custom_ssh_banner}"
}

output "compliance_scanner_config" {
  value     = "${module.compliance_scanner_config.compliance_scanner_config}"
  sensitive = true
}
