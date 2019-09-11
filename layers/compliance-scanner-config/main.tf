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

locals {
  splunk_syslog_port      = "${data.terraform_remote_state.bootstrap_splunk.splunk_syslog_port}"
  splunk_syslog_host_name = "${data.terraform_remote_state.bootstrap_splunk.splunk_syslog_host_name}"
}

module "compliance_scanner_config" {
  source                      = "../../modules/compliance-scanner/config"
  network_name                = "${var.network_name}"
  availability_zones          = "${var.availability_zones}"
  singleton_availability_zone = "${var.singleton_availability_zone}"
  ntp_servers                 = "${var.ntp_servers}"
  syslog_host                 = "${local.splunk_syslog_host_name}"
  syslog_port                 = "${local.splunk_syslog_port}"
}

output "compliance_scanner_config" {
  value     = "${module.compliance_scanner_config.compliance_scanner_config}"
  sensitive = true
}
