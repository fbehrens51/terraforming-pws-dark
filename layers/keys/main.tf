terraform {
  backend "s3" {}
}

provider "aws" {}

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

module "kms" {
  source               = "../../modules/kms/create"
  key_name             = "${var.kms_key_name}"
  pas_bucket_role_name = "${data.terraform_remote_state.paperwork.bucket_role_name}"
  director_role_name   = "${data.terraform_remote_state.paperwork.director_role_name}"
  deletion_window      = 7
}

variable "kms_key_name" {
  type = "string"
}

variable "remote_state_region" {}
variable "remote_state_bucket" {}

output "kms_key_id" {
  value = "${module.kms.kms_key_id}"
}
