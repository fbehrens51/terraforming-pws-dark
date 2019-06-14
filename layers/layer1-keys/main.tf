terraform {
  backend "s3" {}
}

provider "aws" {
  region = "${var.region}"
}

module "providers" {
  source = "../../modules/dark_providers"
}

module "kms" {
  source          = "../../modules/kms/create"
  key_name        = "${var.kms_key_name}"
  deletion_window = 7
}

module "rndc_generator" {
  source   = "../../modules/bind_dns/rndc"
  env_name = "${var.env_name}"
}

variable "kms_key_name" {
  type = "string"
}

variable "region" {}
variable "env_name" {}

output "bind_rndc_secret" {
  value     = "${module.rndc_generator.value}"
  sensitive = true
}
