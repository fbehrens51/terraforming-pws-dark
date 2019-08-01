variable "remote_state_bucket" {}
variable "remote_state_region" {}

//from global vars
variable "availability_zones" {
  type = "list"
}

variable "singleton_availability_zone" {}

variable "network_name" {}

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
  api_endpoint                = "https://api.${data.terraform_remote_state.paperwork.system_domain}"
  splunk_http_collector_url   = "${data.terraform_remote_state.bootstrap_splunk.splunk_http_collector_url}"
  splunk_http_collector_token = "${data.terraform_remote_state.bootstrap_splunk.splunk_http_collector_token}"
}

module "firehose_config" {
  source                      = "../../modules/splunk/firehose-nozzle_config"
  api_endpoint                = "${local.api_endpoint}"
  splunk_url                  = "${local.splunk_http_collector_url}"
  splunk_token                = "${local.splunk_http_collector_token}"
  network_name                = "${var.network_name}"
  availability_zones          = "${var.availability_zones}"
  singleton_availability_zone = "${var.singleton_availability_zone}"
}

output "firehose_config" {
  value     = "${module.firehose_config.firehose_config}"
  sensitive = true
}
