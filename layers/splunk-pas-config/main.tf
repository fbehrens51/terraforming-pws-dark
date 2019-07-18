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
    bucket     = "${var.remote_state_bucket}"
    key        = "paperwork"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

data "terraform_remote_state" "splunk" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "splunk"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

locals {
  api_endpoint = "https://api.${data.terraform_remote_state.paperwork.system_domain}"
}

module "firehose_config" {
  source                      = "../../modules/splunk/firehose-nozzle_config"
  api_endpoint                = "${local.api_endpoint}"
  splunk_url                  = "https://${data.terraform_remote_state.splunk.splunk_private_ips[0]}:8088"
  network_name                = "${var.network_name}"
  availability_zones          = "${var.availability_zones}"
  singleton_availability_zone = "${var.singleton_availability_zone}"
}

output "firehose_config" {
  value = "${module.firehose_config.firehose_config}"
}
