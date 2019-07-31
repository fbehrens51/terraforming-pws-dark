variable "remote_state_bucket" {}
variable "remote_state_region" {}

//from global vars
variable "availability_zones" {
  type = "list"
}

variable "singleton_availability_zone" {}

variable "network_name" {}

variable "env_name" {}

terraform {
  backend "s3" {}
}

module "providers" {
  source = "../../modules/dark_providers"
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

data "terraform_remote_state" "pas" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "pas"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

locals {
  api_endpoint = "https://api.${data.terraform_remote_state.paperwork.system_domain}"
}

module "healthwatch_config" {
  source                         = "../../modules/healthwatch/config"
  om_url                         = "https://${data.terraform_remote_state.pas.om_dns_name}"
  network_name                   = "${var.network_name}"
  availability_zones             = "${var.availability_zones}"
  singleton_availability_zone    = "${var.singleton_availability_zone}"
  health_check_availability_zone = "${var.singleton_availability_zone}"
  env_name                       = "${var.env_name}"
}

resource "random_string" "healthwatch_client_credentials_secret" {
  length  = "32"
  special = false
}

output "healthwatch_config" {
  value = "${module.healthwatch_config.healthwatch_config}"
}

output "healthwatch_client_credentials_secret" {
  value     = "${random_string.healthwatch_client_credentials_secret.result}"
  sensitive = true
}
