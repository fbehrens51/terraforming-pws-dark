terraform {
  backend "s3" {}
}

provider "aws" {
  region = "${var.region}"
}

module "providers" {
  source = "../../modules/dark_providers"
}

data "terraform_remote_state" "routes" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "layer1-routes"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

locals {
  env_name      = "${var.tags["Name"]}"
  modified_name = "${local.env_name} bastion"
  modified_tags = "${merge(var.tags, map("Name", "${local.modified_name}"))}"
}

module "bootstrap_bastion" {
  source            = "../../modules/single_use_subnet"
  availability_zone = "${var.singleton_availability_zone}"
  route_table_id    = "${data.terraform_remote_state.routes.bastion_public_vpc_route_table_id}"
  ingress_rules     = "${var.ingress_rules}"
  egress_rules      = "${var.egress_rules}"
  tags              = "${local.modified_tags}"
  create_eip        = true
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

data "aws_region" "current" {}

module "amazon_ami" {
  source = "../../modules/amis/amazon_hvm_ami"
  region = "${data.aws_region.current.name}"
}

module "bastion_host_key_pair" {
  source = "../../modules/key_pair"
  name   = "${var.bastion_host_key_pair_name}"
}

module "bastion_host" {
  instance_count = "1"
  source         = "../../modules/launch"
  ami_id         = "${module.amazon_ami.id}"
  user_data      = "${data.template_cloudinit_config.user_data.rendered}"
  eni_ids        = ["${module.bootstrap_bastion.eni_id}"]
  key_pair_name  = "${var.bastion_host_key_pair_name}"
  tags           = "${local.modified_tags}"
}

variable "remote_state_region" {}
variable "remote_state_bucket" {}
variable "user_data_path" {}
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

variable "bastion_host_key_pair_name" {}
variable "region" {}
