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

data "aws_vpc" "bastion_vpc" {
  id = "${data.terraform_remote_state.paperwork.bastion_vpc_id}"
}

data "aws_vpc" "pas_vpc" {
  id = "${data.terraform_remote_state.paperwork.pas_vpc_id}"
}

data "aws_vpc" "cp_vpc" {
  id = "${data.terraform_remote_state.paperwork.cp_vpc_id}"
}

data "aws_vpc" "es_vpc" {
  id = "${data.terraform_remote_state.paperwork.es_vpc_id}"
}

data "aws_vpc_peering_connection" "pas_bastion_peering_connection" {
  vpc_id      = "${data.terraform_remote_state.paperwork.pas_vpc_id}"
  peer_vpc_id = "${data.terraform_remote_state.paperwork.bastion_vpc_id}"
}

resource "aws_route" "pas_private_to_bastion" {
  route_table_id            = "${module.vpc_route_tables.pas_private_vpc_route_table_id}"
  destination_cidr_block    = "${data.aws_vpc.bastion_vpc.cidr_block}"
  vpc_peering_connection_id = "${data.aws_vpc_peering_connection.pas_bastion_peering_connection.id}"

  timeouts {
    create = "5m"
  }
}

data "aws_vpc_peering_connection" "es_bastion_peering_connection" {
  vpc_id      = "${data.terraform_remote_state.paperwork.es_vpc_id}"
  peer_vpc_id = "${data.terraform_remote_state.paperwork.bastion_vpc_id}"
}

data "aws_vpc_peering_connection" "es_pas_peering_connection" {
  vpc_id      = "${data.terraform_remote_state.paperwork.es_vpc_id}"
  peer_vpc_id = "${data.terraform_remote_state.paperwork.pas_vpc_id}"
}

data "aws_vpc_peering_connection" "pas_cp_peering_connection" {
  vpc_id      = "${data.terraform_remote_state.paperwork.pas_vpc_id}"
  peer_vpc_id = "${data.terraform_remote_state.paperwork.cp_vpc_id}"
}

data "aws_vpc_peering_connection" "cp_bastion_peering_connection" {
  vpc_id      = "${data.terraform_remote_state.paperwork.cp_vpc_id}"
  peer_vpc_id = "${data.terraform_remote_state.paperwork.bastion_vpc_id}"
}

data "aws_vpc_peering_connection" "es_cp_peering_connection" {
  vpc_id      = "${data.terraform_remote_state.paperwork.es_vpc_id}"
  peer_vpc_id = "${data.terraform_remote_state.paperwork.cp_vpc_id}"
}

resource "aws_route" "cp_public_to_es" {
  route_table_id            = "${module.vpc_route_tables.cp_public_vpc_route_table_id}"
  destination_cidr_block    = "${data.aws_vpc.es_vpc.cidr_block}"
  vpc_peering_connection_id = "${data.aws_vpc_peering_connection.es_cp_peering_connection.id}"

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "cp_private_to_bastion" {
  route_table_id            = "${module.vpc_route_tables.cp_private_vpc_route_table_id}"
  destination_cidr_block    = "${data.aws_vpc.bastion_vpc.cidr_block}"
  vpc_peering_connection_id = "${data.aws_vpc_peering_connection.cp_bastion_peering_connection.id}"

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "cp_private_to_pas" {
  route_table_id            = "${module.vpc_route_tables.cp_private_vpc_route_table_id}"
  destination_cidr_block    = "${data.aws_vpc.pas_vpc.cidr_block}"
  vpc_peering_connection_id = "${data.aws_vpc_peering_connection.pas_cp_peering_connection.id}"

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "es_private_to_bastion" {
  route_table_id            = "${module.vpc_route_tables.es_private_vpc_route_table_id}"
  destination_cidr_block    = "${data.aws_vpc.bastion_vpc.cidr_block}"
  vpc_peering_connection_id = "${data.aws_vpc_peering_connection.es_bastion_peering_connection.id}"

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "es_private_to_pas" {
  route_table_id            = "${module.vpc_route_tables.es_private_vpc_route_table_id}"
  destination_cidr_block    = "${data.aws_vpc.pas_vpc.cidr_block}"
  vpc_peering_connection_id = "${data.aws_vpc_peering_connection.es_pas_peering_connection.id}"

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "pas_public_to_cp" {
  route_table_id            = "${module.vpc_route_tables.pas_public_vpc_route_table_id}"
  destination_cidr_block    = "${data.aws_vpc.cp_vpc.cidr_block}"
  vpc_peering_connection_id = "${data.aws_vpc_peering_connection.pas_cp_peering_connection.id}"

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "es_public_to_cp" {
  route_table_id            = "${module.vpc_route_tables.es_public_vpc_route_table_id}"
  destination_cidr_block    = "${data.aws_vpc.cp_vpc.cidr_block}"
  vpc_peering_connection_id = "${data.aws_vpc_peering_connection.es_cp_peering_connection.id}"

  timeouts {
    create = "5m"
  }
}

// We can't know in general which vpc is the accepter vs the requester,
// so these modules have to be copied in each environment
module "route_bastion_pas" {
  source                   = "../../modules/routing"
  accepter_route_table_id  = "${module.vpc_route_tables.bastion_public_vpc_route_table_id}"
  requester_route_table_id = "${module.vpc_route_tables.pas_public_vpc_route_table_id}"
}

module "route_bastion_control_plane" {
  source                   = "../../modules/routing"
  accepter_route_table_id  = "${module.vpc_route_tables.bastion_public_vpc_route_table_id}"
  requester_route_table_id = "${module.vpc_route_tables.cp_public_vpc_route_table_id}"
}

module "route_bastion_enterprise_services" {
  source                   = "../../modules/routing"
  accepter_route_table_id  = "${module.vpc_route_tables.bastion_public_vpc_route_table_id}"
  requester_route_table_id = "${module.vpc_route_tables.es_public_vpc_route_table_id}"
}

module "route_pas_private_es" {
  source                   = "../../modules/routing"
  accepter_route_table_id  = "${module.vpc_route_tables.pas_private_vpc_route_table_id}"
  requester_route_table_id = "${module.vpc_route_tables.es_public_vpc_route_table_id}"
}

module "route_cp_pas_private" {
  source                   = "../../modules/routing"
  accepter_route_table_id  = "${module.vpc_route_tables.cp_public_vpc_route_table_id}"
  requester_route_table_id = "${module.vpc_route_tables.pas_private_vpc_route_table_id}"
}

module "route_cp_private_es" {
  source                   = "../../modules/routing"
  accepter_route_table_id  = "${module.vpc_route_tables.cp_private_vpc_route_table_id}"
  requester_route_table_id = "${module.vpc_route_tables.es_private_vpc_route_table_id}"
}

variable "remote_state_region" {}
variable "remote_state_bucket" {}
variable "internetless" {}

variable "env_name" {
  type = "string"
}
