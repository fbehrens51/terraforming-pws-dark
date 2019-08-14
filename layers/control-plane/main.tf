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

module "bootstrap_control_plane" {
  source            = "../../modules/single_use_subnet"
  availability_zone = "${var.singleton_availability_zone}"
  cidr_block        = "${data.aws_vpc.vpc.cidr_block}"
  route_table_id    = "${data.terraform_remote_state.routes.cp_public_vpc_route_table_id}"
  ingress_rules     = "${var.ingress_rules}"
  egress_rules      = "${var.egress_rules}"
  tags              = "${local.modified_tags}"
  create_eip        = false
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
  env_name      = "${var.tags["Name"]}"
  modified_name = "${local.env_name} control plane"
  modified_tags = "${merge(var.tags, map("Name", "${local.modified_name}"))}"
}

module "sjb" {
  instance_count       = 1
  source               = "../../modules/launch"
  ami_id               = "${module.find_ami.id}"
  user_data            = "${data.template_cloudinit_config.user_data.rendered}"
  eni_ids              = ["${module.bootstrap_control_plane.eni_id}"]
  key_pair_name        = "${var.control_plane_host_key_pair_name}"
  iam_instance_profile = "${data.terraform_remote_state.paperwork.director_role_name}"
  instance_type        = "${var.instance_type}"
  tags                 = "${local.modified_tags}"

  root_block_device = {
    volume_type = "gp2"
    volume_size = 64
  }
}

resource "aws_eip" "temp_sjb" {}

resource "aws_eip_association" "sjb_assoc" {
  allocation_id = "${aws_eip.temp_sjb.id}"
  instance_id   = "${module.sjb.instance_ids[0]}"
}

variable "singleton_availability_zone" {}

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
