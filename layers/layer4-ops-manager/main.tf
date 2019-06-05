provider "aws" {
  region = "${var.region}"
}

module "providers" {
  source = "../../modules/dark_providers"
}

terraform {
  backend "s3" {}
}

data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "layer0-paperwork"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

data "terraform_remote_state" "pas" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "layer3-pas"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

locals {
  vpc_id                      = "${data.terraform_remote_state.paperwork.pas_vpc_id}"
  director_role_name          = "${data.terraform_remote_state.paperwork.director_role_name}"
  om_security_group_id        = "${data.terraform_remote_state.pas.om_security_group_id}"
  om_ssh_public_key_pair_name = "${data.terraform_remote_state.pas.om_ssh_public_key_pair_name}"
  om_elb_id                   = "${data.terraform_remote_state.pas.om_elb_id}"
  om_eip_allocation_id        = "${data.terraform_remote_state.pas.om_eip_allocation_id}"
  om_eni_id                   = "${data.terraform_remote_state.pas.om_eni_id}"

  tags = "${merge(var.tags, map("Name", "${var.env_name}-opsman"))}"
}

variable "remote_state_bucket" {}
variable "remote_state_region" {}
variable "region" {}

variable "om_ami_id" {}

variable "env_name" {}

variable "tags" {
  type = "map"
}

variable "instance_type" {}

module "ops_manager" {
  source           = "../../modules/ops_manager/instance"
  ami              = "${var.om_ami_id}"
  instance_profile = "${local.director_role_name}"
  instance_type    = "${var.instance_type}"
  key_pair_name    = "${local.om_ssh_public_key_pair_name}"
  tags             = "${local.tags}"
  eni_id           = "${local.om_eni_id}"
  env_name         = "${var.env_name}"
}

resource "aws_elb_attachment" "opsman_attach" {
  elb      = "${local.om_elb_id}"
  instance = "${module.ops_manager.instance_id}"
}

resource "aws_eip_association" "om_eip_assoc" {
  count         = "${length(local.om_eip_allocation_id)>0 ? 1 : 0}"
  instance_id   = "${module.ops_manager.instance_id}"
  allocation_id = "${local.om_eip_allocation_id}"
}
