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

locals {
  pas_vpc_id     = "${data.terraform_remote_state.paperwork.pas_vpc_id}"
  es_vpc_id      = "${data.terraform_remote_state.paperwork.es_vpc_id}"
  cp_vpc_id      = "${data.terraform_remote_state.paperwork.cp_vpc_id}"
  bastion_vpc_id = "${data.terraform_remote_state.paperwork.bastion_vpc_id}"

  pas_s3_vpc_endpoint_id     = "${data.terraform_remote_state.paperwork.pas_s3_vpc_endpoint_id}"
  es_s3_vpc_endpoint_id      = "${data.terraform_remote_state.paperwork.es_s3_vpc_endpoint_id}"
  cp_s3_vpc_endpoint_id      = "${data.terraform_remote_state.paperwork.cp_s3_vpc_endpoint_id}"
  bastion_s3_vpc_endpoint_id = "${data.terraform_remote_state.paperwork.bastion_s3_vpc_endpoint_id}"
}

module "pas_vpc_route_tables" {
  source             = "./modules/vpc_route_tables"
  internetless       = "${var.internetless}"
  vpc_id             = "${local.pas_vpc_id}"
  s3_vpc_endpoint_id = "${local.pas_s3_vpc_endpoint_id}"
  availability_zones = "${var.availability_zones}"

  tags = {
    Name = "${var.env_name} | PAS"
  }
}

module "bastion_vpc_route_tables" {
  source             = "./modules/vpc_route_tables"
  internetless       = "${var.internetless}"
  vpc_id             = "${local.bastion_vpc_id}"
  s3_vpc_endpoint_id = "${local.bastion_s3_vpc_endpoint_id}"
  availability_zones = "${var.availability_zones}"

  tags = {
    Name = "${var.env_name} | BASTION"
  }
}

module "es_vpc_route_tables" {
  source             = "./modules/vpc_route_tables"
  internetless       = "${var.internetless}"
  vpc_id             = "${local.es_vpc_id}"
  s3_vpc_endpoint_id = "${local.es_s3_vpc_endpoint_id}"
  availability_zones = "${var.availability_zones}"

  tags = {
    Name = "${var.env_name} | ENT SVCS"
  }
}

module "cp_vpc_route_tables" {
  source             = "./modules/vpc_route_tables"
  internetless       = "${var.internetless}"
  vpc_id             = "${local.cp_vpc_id}"
  s3_vpc_endpoint_id = "${local.cp_s3_vpc_endpoint_id}"
  availability_zones = "${var.availability_zones}"

  tags = {
    Name = "${var.env_name} | CP"
  }
}

module "route_bastion_cp" {
  source                    = "./modules/routing"
  accepter_vpc_id           = "${local.bastion_vpc_id}"
  requester_vpc_id          = "${local.cp_vpc_id}"
  accepter_route_table_ids  = "${concat(module.bastion_vpc_route_tables.private_route_table_ids,list( module.bastion_vpc_route_tables.public_route_table_id ))}"
  requester_route_table_ids = "${concat(module.cp_vpc_route_tables.private_route_table_ids,list( module.cp_vpc_route_tables.public_route_table_id ))}"
  availability_zones        = "${var.availability_zones}"
}

module "route_bastion_pas" {
  source                    = "./modules/routing"
  accepter_vpc_id           = "${local.bastion_vpc_id}"
  requester_vpc_id          = "${local.pas_vpc_id}"
  accepter_route_table_ids  = "${concat(module.bastion_vpc_route_tables.private_route_table_ids,list( module.bastion_vpc_route_tables.public_route_table_id ))}"
  requester_route_table_ids = "${concat(module.pas_vpc_route_tables.private_route_table_ids,list( module.pas_vpc_route_tables.public_route_table_id ))}"
  availability_zones        = "${var.availability_zones}"
}

module "route_bastion_es" {
  source                    = "./modules/routing"
  accepter_vpc_id           = "${local.bastion_vpc_id}"
  requester_vpc_id          = "${local.es_vpc_id}"
  accepter_route_table_ids  = "${concat(module.bastion_vpc_route_tables.private_route_table_ids,list( module.bastion_vpc_route_tables.public_route_table_id ))}"
  requester_route_table_ids = "${concat(module.es_vpc_route_tables.private_route_table_ids,list( module.es_vpc_route_tables.public_route_table_id ))}"
  availability_zones        = "${var.availability_zones}"
}

module "route_cp_pas" {
  source                    = "./modules/routing"
  accepter_vpc_id           = "${local.cp_vpc_id}"
  requester_vpc_id          = "${local.pas_vpc_id}"
  accepter_route_table_ids  = "${concat(module.cp_vpc_route_tables.private_route_table_ids,list( module.cp_vpc_route_tables.public_route_table_id ))}"
  requester_route_table_ids = "${concat(module.pas_vpc_route_tables.private_route_table_ids,list( module.pas_vpc_route_tables.public_route_table_id ))}"
  availability_zones        = "${var.availability_zones}"
}

module "route_cp_es" {
  source                    = "./modules/routing"
  accepter_vpc_id           = "${local.cp_vpc_id}"
  requester_vpc_id          = "${local.es_vpc_id}"
  accepter_route_table_ids  = "${concat(module.cp_vpc_route_tables.private_route_table_ids,list( module.cp_vpc_route_tables.public_route_table_id ))}"
  requester_route_table_ids = "${concat(module.es_vpc_route_tables.private_route_table_ids,list( module.es_vpc_route_tables.public_route_table_id ))}"
  availability_zones        = "${var.availability_zones}"
}

module "route_pas_es" {
  source                    = "./modules/routing"
  accepter_vpc_id           = "${local.pas_vpc_id}"
  requester_vpc_id          = "${local.es_vpc_id}"
  accepter_route_table_ids  = "${concat(module.pas_vpc_route_tables.private_route_table_ids,list( module.pas_vpc_route_tables.public_route_table_id ))}"
  requester_route_table_ids = "${concat(module.es_vpc_route_tables.private_route_table_ids,list( module.es_vpc_route_tables.public_route_table_id ))}"
  availability_zones        = "${var.availability_zones}"
}

variable "remote_state_region" {}
variable "remote_state_bucket" {}
variable "internetless" {}

variable "env_name" {
  type = "string"
}

variable "availability_zones" {
  type = "list"
}
