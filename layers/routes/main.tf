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

provider "aws" {}

module "providers" {
  source = "../../modules/dark_providers"
}

module "vpc_route_tables" {
  source         = "../../modules/routing/vpc_route_tables"
  pas_vpc_id     = "${data.terraform_remote_state.paperwork.pas_vpc_id}"
  bastion_vpc_id = "${data.terraform_remote_state.paperwork.bastion_vpc_id}"
  es_vpc_id      = "${data.terraform_remote_state.paperwork.es_vpc_id}"
  cp_vpc_id      = "${data.terraform_remote_state.paperwork.cp_vpc_id}"
  env_name       = "${var.env_name}"
  internetless   = "${var.internetless}"
}

module "route_bastion_cp" {
  source                   = "../../modules/routing"
  accepter_vpc_id  = "${data.terraform_remote_state.paperwork.bastion_vpc_id}"
  requester_vpc_id = "${data.terraform_remote_state.paperwork.cp_vpc_id}"
}

module "route_bastion_pas" {
  source                   = "../../modules/routing"
  accepter_vpc_id  = "${data.terraform_remote_state.paperwork.bastion_vpc_id}"
  requester_vpc_id = "${data.terraform_remote_state.paperwork.pas_vpc_id}"
}

module "route_bastion_es" {
  source                   = "../../modules/routing"
  accepter_vpc_id  = "${data.terraform_remote_state.paperwork.bastion_vpc_id}"
  requester_vpc_id = "${data.terraform_remote_state.paperwork.es_vpc_id}"
}

module "route_cp_pas" {
  source                   = "../../modules/routing"
  accepter_vpc_id  = "${data.terraform_remote_state.paperwork.cp_vpc_id}"
  requester_vpc_id = "${data.terraform_remote_state.paperwork.pas_vpc_id}"
}

module "route_cp_es" {
  source                   = "../../modules/routing"
  accepter_vpc_id  = "${data.terraform_remote_state.paperwork.cp_vpc_id}"
  requester_vpc_id = "${data.terraform_remote_state.paperwork.es_vpc_id}"
}

module "route_pas_es" {
  source                   = "../../modules/routing"
  accepter_vpc_id  = "${data.terraform_remote_state.paperwork.pas_vpc_id}"
  requester_vpc_id = "${data.terraform_remote_state.paperwork.es_vpc_id}"
}

variable "remote_state_region" {}
variable "remote_state_bucket" {}
variable "internetless" {}

variable "env_name" {
  type = "string"
}
