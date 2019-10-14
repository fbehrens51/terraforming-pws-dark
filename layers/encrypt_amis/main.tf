terraform {
  backend "s3" {}
}

provider "aws" {}

module "providers" {
  source = "../../modules/dark_providers"
}

variable "remote_state_region" {}
variable "remote_state_bucket" {}

data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "paperwork"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

module "encrypt_amazon2_ami" {
  source     = "../../modules/amis/encrypted/amazon2/create"
  kms_key_id = "${data.terraform_remote_state.paperwork.kms_key_arn}"
}

// snapshot times out, subsequent run will pick up completed snapshot and complete successfully...
// so need to refactor into script/local exec to handle long running snapshots.
module "encrypt_om_ami" {
  source     = "../../modules/amis/encrypted/opsman/create"
  kms_key_id = "${data.terraform_remote_state.paperwork.kms_key_arn}"
}
