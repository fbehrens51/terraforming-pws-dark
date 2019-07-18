terraform {
  backend "s3" {}
}

provider "aws" {
  region = "${var.region}"
}

module "providers" {
  source = "../../modules/dark_providers"
}

data "terraform_remote_state" "keys" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "keys"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

data "terraform_remote_state" "enterprise-services" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "enterprise-services"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

locals {
  env_name          = "${var.tags["Name"]}"
  modified_name     = "${local.env_name} bind"
  modified_tags     = "${merge(var.tags, map("Name", "${local.modified_name}"))}"
  bind_rndc_secret  = "${data.terraform_remote_state.keys.bind_rndc_secret}"
  master_private_ip = "${data.terraform_remote_state.enterprise-services.bind_eni_ips[0]}"
  master_public_ip  = "${data.terraform_remote_state.enterprise-services.bind_eip_ips[0]}"
}

data "aws_region" "current" {}

module "amazon_ami" {
  source = "../../modules/amis/amazon_hvm_ami"
  region = "${data.aws_region.current.name}"
}

module "bind_host_key_pair" {
  source   = "../../modules/key_pair"
  key_name = "${local.modified_name}"
}

module "bind_master_user_data" {
  source      = "../../modules/bind_dns/master/user_data"
  client_cidr = "${var.client_cidr}"
  master_ip   = "${local.master_public_ip}"
  secret      = "${local.bind_rndc_secret}"
  slave_ips   = ["${data.terraform_remote_state.enterprise-services.bind_eip_ips[1]}", "${data.terraform_remote_state.enterprise-services.bind_eip_ips[2]}"]
  zone_name   = "${var.zone_name}"
}

module "bind_master_host" {
  instance_count = 1
  source         = "../../modules/launch"
  ami_id         = "${module.amazon_ami.id}"
  user_data      = "${module.bind_master_user_data.user_data}"
  eni_ids        = "${data.terraform_remote_state.enterprise-services.bind_eni_ids}"
  key_pair_name  = "${module.bind_host_key_pair.key_name}"
  tags           = "${local.modified_tags}"
}

module "bind_slave_user_data" {
  source      = "../../modules/bind_dns/slave/user_data"
  client_cidr = "${var.client_cidr}"
  master_ip   = "${local.master_public_ip}"
  zone_name   = "${var.zone_name}"
}

module "bind_slave_host" {
  instance_count = "${length(data.terraform_remote_state.enterprise-services.bind_eni_ids) - 1}"
  source         = "../../modules/launch"
  ami_id         = "${module.amazon_ami.id}"
  user_data      = "${module.bind_slave_user_data.user_data}"
  eni_ids        = ["${data.terraform_remote_state.enterprise-services.bind_eni_ids[1]}", "${data.terraform_remote_state.enterprise-services.bind_eni_ids[2]}"]
  key_pair_name  = "${module.bind_host_key_pair.key_name}"
  tags           = "${local.modified_tags}"
}

resource "aws_eip_association" "bind_master_eip_assoc" {
  count         = "${length(data.terraform_remote_state.enterprise-services.bind_eni_ids) > 0 ? 1 : 0}"
  instance_id   = "${module.bind_master_host.instance_ids[count.index]}"
  allocation_id = "${data.terraform_remote_state.enterprise-services.bind_eip_ids[count.index]}"
}

locals {
  //Was trying to do this inline below, but I couldn't get terraform to understand it when trying to use [count.index] afterwards
  //Maybe we should be splitting apart the master vs slave lists earlier in the chain?  potentially create them separately?  The approach we're currently
  //taking feels a little hackish and brittle.  I have a feeling the eip part would break when we don't create them in enterprise-services for the other network
  slave_eip_list = ["${data.terraform_remote_state.enterprise-services.bind_eip_ids[1]}", "${data.terraform_remote_state.enterprise-services.bind_eip_ids[2]}"]
}

resource "aws_eip_association" "bind_slave_eip_assoc" {
  count         = "${length(data.terraform_remote_state.enterprise-services.bind_eni_ids) > 1 ? length(data.terraform_remote_state.enterprise-services.bind_eni_ids) - 1 : 0}"
  instance_id   = "${module.bind_slave_host.instance_ids[count.index]}"
  allocation_id = "${local.slave_eip_list[count.index]}"
}

variable "env_name" {}
variable "remote_state_region" {}
variable "remote_state_bucket" {}
variable "region" {}

variable "tags" {
  type = "map"
}

output "bind_ssh_private_key" {
  value     = "${module.bind_host_key_pair.private_key_pem}"
  sensitive = true
}

output "master_private_ip" {
  value = "${local.master_private_ip}"
}

output "master_public_ip" {
  value = "${local.master_public_ip}"
}

output "zone_name" {
  value = "${var.zone_name}"
}

variable "client_cidr" {}

variable "zone_name" {}
