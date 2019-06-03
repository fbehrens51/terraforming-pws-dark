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

variable "kms_key_name" {
  type = "string"
}

variable "region" {}
