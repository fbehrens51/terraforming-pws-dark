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
    bucket     = "${var.remote_state_bucket}"
    key        = "paperwork"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

data "terraform_remote_state" "bastion" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "bastion"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

data "terraform_remote_state" "routes" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "routes"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

locals {
  env_name      = "${var.tags["Name"]}"
  modified_name = "${local.env_name} enterprise services"
  modified_tags = "${merge(var.tags, map("Name", "${local.modified_name}"))}"
  es_vpc_id     = "${data.terraform_remote_state.paperwork.es_vpc_id}"


  splunk_volume_tag = "${var.env_name}-SPLUNK_DATA"


  public_cidr_block  = "${cidrsubnet(data.aws_vpc.this_vpc.cidr_block, 1, 0)}"
  private_cidr_block = "${cidrsubnet(data.aws_vpc.this_vpc.cidr_block, 1, 1)}"
}

data "aws_vpc" "this_vpc" {
  id = "${local.es_vpc_id}"
}

module "public_subnets" {
  source            = "../../modules/subnet_per_az"
  availability_zones = "${var.availability_zones}"
  vpc_id            = "${local.es_vpc_id}"
  cidr_block        = "${local.public_cidr_block}"
  tags = "${merge(local.modified_tags, map("Name", "${local.modified_name}-public"))}"
}

resource "aws_route_table_association" "public_route_table_assoc" {
  count          = "${length(var.availability_zones)}"
  subnet_id      = "${module.public_subnets.subnet_ids[count.index]}"
  route_table_id = "${data.terraform_remote_state.routes.es_public_vpc_route_table_id}"
}

module "private_subnets" {
  source            = "../../modules/subnet_per_az"
  availability_zones = "${var.availability_zones}"
  vpc_id            = "${local.es_vpc_id}"
  cidr_block        = "${local.private_cidr_block}"
  tags = "${merge(local.modified_tags, map("Name", "${local.modified_name}-private"))}"
}

resource "aws_route_table_association" "private_route_table_assoc" {
  count          = "${length(var.availability_zones)}"
  subnet_id      = "${module.private_subnets.subnet_ids[count.index]}"
  route_table_id = "${data.terraform_remote_state.routes.es_private_vpc_route_table_id}"
}

resource "aws_eip" "nat_eip" {
  count = "${var.internetless ? 0 : 1}"
  vpc = true
  tags = "${merge(local.modified_tags, map("Name", "${local.modified_name}-nat"))}"
}

resource "aws_nat_gateway" "nat" {
  count         = "${var.internetless ? 0 : 1}"
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${element(module.public_subnets.subnet_ids, 0)}"

  tags = "${merge(local.modified_tags, map("Name", "${local.modified_name}-nat"))}"
}

resource "aws_route" "toggle_internet" {
  count = "${var.internetless ? 0 : 1}"

  route_table_id         =  "${data.terraform_remote_state.routes.es_private_vpc_route_table_id}"
  nat_gateway_id         = "${aws_nat_gateway.nat.id}"
  destination_cidr_block = "0.0.0.0/0"
}

# module "bootstrap_ldap" {
#   source            = "../../modules/single_use_subnet"
#   cidr_block        = "${local.ldap_cidr_block}"
#   availability_zone = "${var.singleton_availability_zone}"
#   route_table_id    = "${data.terraform_remote_state.routes.es_public_vpc_route_table_id}"
#   ingress_rules     = "${local.ldap_ingress_rules}"
#   egress_rules      = "${local.ldap_egress_rules}"
#   tags              = "${local.modified_tags}"
#   create_eip        = true
# }

# module "bootstrap_splunk" {
#   source            = "../../modules/single_use_subnet"
#   cidr_block        = "${local.splunk_cidr_block}"
#   availability_zone = "${var.singleton_availability_zone}"
#   route_table_id    = "${data.terraform_remote_state.routes.es_public_vpc_route_table_id}"
#   ingress_rules     = "${local.splunk_ingress_rules}"
#   egress_rules      = "${local.splunk_egress_rules}"
#   tags              = "${local.modified_tags}"
#   create_eip        = true
# }

variable "env_name" {}
variable "internetless" {}
variable "remote_state_region" {}
variable "remote_state_bucket" {}
variable "singleton_availability_zone" {}

variable "tags" {
  type = "map"
}

variable "availability_zones" {
  type = "list"
}

output "public_subnet_ids" {
  value = "${module.public_subnets.subnet_ids}"
}

output "public_subnet_cidrs" {
  value = "${module.public_subnets.subnet_cidr_blocks}"
}

output "private_subnet_ids" {
  value = "${module.private_subnets.subnet_ids}"
}

output "private_subnet_cidrs" {
  value = "${module.private_subnets.subnet_cidr_blocks}"
}
