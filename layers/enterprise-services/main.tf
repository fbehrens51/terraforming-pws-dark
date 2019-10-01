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

data "terraform_remote_state" "bastion" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "bastion"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

data "terraform_remote_state" "routes" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "routes"
    region  = "${var.remote_state_region}"
    encrypt = true
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
  source             = "../../modules/subnet_per_az"
  availability_zones = "${var.availability_zones}"
  vpc_id             = "${local.es_vpc_id}"
  cidr_block         = "${local.public_cidr_block}"
  tags               = "${merge(local.modified_tags, map("Name", "${local.modified_name}-public"))}"
}

resource "aws_route_table_association" "public_route_table_assoc" {
  count          = "${length(var.availability_zones)}"
  subnet_id      = "${module.public_subnets.subnet_ids[count.index]}"
  route_table_id = "${data.terraform_remote_state.routes.es_public_vpc_route_table_id}"
}

module "private_subnets" {
  source             = "../../modules/subnet_per_az"
  availability_zones = "${var.availability_zones}"
  vpc_id             = "${local.es_vpc_id}"
  cidr_block         = "${local.private_cidr_block}"
  tags               = "${merge(local.modified_tags, map("Name", "${local.modified_name}-private"))}"
}

resource "aws_route_table_association" "private_route_table_assoc" {
  count          = "${length(var.availability_zones)}"
  subnet_id      = "${module.private_subnets.subnet_ids[count.index]}"
  route_table_id = "${data.terraform_remote_state.routes.es_private_vpc_route_table_id}"
}

module "amzn1_clam_av_client_config" {
  source           = "../../modules/clamav/amzn1_initd_client"
  clamav_db_mirror = "${var.clamav_db_mirror}"
}

data "template_cloudinit_config" "nat_user_data" {
  part {
    filename     = "clamav.cfg"
    content_type = "text/cloud-config"
    content      = "${module.amzn1_clam_av_client_config.client_cloud_config}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }
}

module "nat" {
  source                 = "../../modules/nat"
  private_route_table_id = "${data.terraform_remote_state.routes.es_private_vpc_route_table_id}"
  tags                   = "${local.modified_tags}"
  public_subnet_id       = "${element(module.public_subnets.subnet_ids, 0)}"
  internetless           = "${var.internetless}"
  instance_type          = "${var.nat_instance_type}"
  user_data              = "${data.template_cloudinit_config.nat_user_data.rendered}"
  ssh_banner             = "${data.terraform_remote_state.paperwork.custom_ssh_banner}"
}

variable "nat_instance_type" {
  default = "t2.small"
}

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

variable "clamav_db_mirror" {}

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
