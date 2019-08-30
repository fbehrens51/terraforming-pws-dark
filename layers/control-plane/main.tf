terraform {
  backend "s3" {}
}

provider "aws" {}

data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "paperwork"
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

data "aws_vpc" "vpc" {
  id = "${data.terraform_remote_state.paperwork.cp_vpc_id}"
}

module "providers" {
  source = "../../modules/dark_providers"
}

module "public_subnets" {
  source             = "../../modules/subnet_per_az"
  availability_zones = ["${var.singleton_availability_zone}"]
  vpc_id             = "${data.aws_vpc.vpc.id}"
  cidr_block         = "${local.public_cidr_block}"
  tags               = "${merge(local.modified_tags, map("Name", "${local.modified_name}-public"))}"
}

resource "aws_route_table_association" "public_route_table_assoc" {
  count          = "1"
  subnet_id      = "${module.public_subnets.subnet_ids[count.index]}"
  route_table_id = "${data.terraform_remote_state.routes.cp_public_vpc_route_table_id}"
}

module "private_subnets" {
  source             = "../../modules/subnet_per_az"
  availability_zones = ["${var.singleton_availability_zone}"]
  vpc_id             = "${data.aws_vpc.vpc.id}"
  cidr_block         = "${local.private_cidr_block}"
  tags               = "${merge(local.modified_tags, map("Name", "${local.modified_name}-private"))}"
}

resource "aws_route_table_association" "private_route_table_assoc" {
  count          = "1"
  subnet_id      = "${module.private_subnets.subnet_ids[count.index]}"
  route_table_id = "${data.terraform_remote_state.routes.cp_private_vpc_route_table_id}"
}

data "template_cloudinit_config" "user_data" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "other.cfg"
    content_type = "text/cloud-config"
    content      = "${file("${var.user_data_path}")}"
  }
}

module "find_ami" {
  source = "../../modules/amis/amazon_hvm_ami"
}

module "control_plane_host_key_pair" {
  source   = "../../modules/key_pair"
  key_name = "${var.control_plane_host_key_pair_name}"
}

locals {
  env_name           = "${var.tags["Name"]}"
  modified_name      = "${local.env_name} control plane"
  modified_tags      = "${merge(var.tags, map("Name", "${local.modified_name}"))}"
  public_cidr_block  = "${cidrsubnet(data.aws_vpc.vpc.cidr_block, 1, 0)}"
  private_cidr_block = "${cidrsubnet(data.aws_vpc.vpc.cidr_block, 1, 1)}"
}

module "sjb_bootstrap" {
  source        = "../../modules/eni_per_subnet"
  ingress_rules = "${var.ingress_rules}"
  egress_rules  = "${var.egress_rules}"
  subnet_ids    = "${module.private_subnets.subnet_ids}"
  eni_count     = "1"
  create_eip    = "false"
  tags          = "${local.modified_tags}"
}

module "sjb" {
  instance_count       = 1
  source               = "../../modules/launch"
  ami_id               = "${module.find_ami.id}"
  user_data            = "${data.template_cloudinit_config.user_data.rendered}"
  eni_ids              = "${module.sjb_bootstrap.eni_ids}"
  key_pair_name        = "${var.control_plane_host_key_pair_name}"
  iam_instance_profile = "${data.terraform_remote_state.paperwork.director_role_name}"
  instance_type        = "${var.instance_type}"
  tags                 = "${local.modified_tags}"

  root_block_device = {
    volume_type = "gp2"
    volume_size = 64
  }
}

module "nat" {
  source                 = "../../modules/nat"
  private_route_table_id = "${data.terraform_remote_state.routes.cp_private_vpc_route_table_id}"
  tags                   = "${local.modified_tags}"
  public_subnet_id       = "${module.public_subnets.subnet_ids[0]}"
  internetless           = "${var.internetless}"
  instance_type          = "${var.nat_instance_type}"
}

variable "singleton_availability_zone" {}
variable "internetless" {}

variable "nat_instance_type" {
  default = "t2.small"
}

variable "ingress_rules" {
  type = "list"
}

variable "egress_rules" {
  type = "list"
}

variable "tags" {
  type = "map"
}

variable "user_data_path" {}
variable "remote_state_bucket" {}
variable "remote_state_region" {}
variable "control_plane_host_key_pair_name" {}
variable "instance_type" {}
