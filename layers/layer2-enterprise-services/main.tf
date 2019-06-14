terraform {
  backend "s3" {}
}

provider "aws" {
  region = "${var.region}"
}

module "providers" {
  source = "../../modules/dark_providers"
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

data "terraform_remote_state" "bastion" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "layer2-bastion"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
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
  modified_name = "${local.env_name} enterprise services"
  modified_tags = "${merge(var.tags, map("Name", "${local.modified_name}"))}"
  es_vpc_id     = "${data.terraform_remote_state.paperwork.es_vpc_id}"

  //allow dns to reach out anywhere. This is needed for CNAME records to external DNS
  egress_rules = [
    {
      port        = "53"
      protocol    = "udp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port        = "53"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      //yum for bind install
      port        = "80"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  ingress_rules = [
    {
      port        = "53"
      protocol    = "udp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port        = "53"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = "${data.terraform_remote_state.bastion.bastion_cidr_block}"
    },
  ]
}

module "bootstrap_es" {
  source             = "../../modules/multiple_subnet_vpc"
  availability_zones = "${var.availability_zones}"
  vpc_id             = "${local.es_vpc_id}"
  newbits            = "4"
  route_table_id     = "${data.terraform_remote_state.routes.es_public_vpc_route_table_id}"
  ingress_rules      = ["${local.ingress_rules}"]
  egress_rules       = ["${local.egress_rules}"]
  tags               = "${local.modified_tags}"
  create_eip         = true
}

module "amazon_ami" {
  source = "../../modules/amis/amazon_hvm_ami"
  region = "${var.region}"
}

variable "env_name" {}
variable "remote_state_region" {}
variable "remote_state_bucket" {}
variable "singleton_availability_zone" {}
variable "region" {}

variable "tags" {
  type = "map"
}

variable "availability_zones" {
  type = "list"
}

output "es_subnet_ids" {
  value = "${module.bootstrap_es.subnet_ids}"
}

output "bind_eni_ids" {
  value = "${module.bootstrap_es.eni_ids}"
}

output "bind_eip_ids" {
  value = "${module.bootstrap_es.eip_ids}"
}

output "bind_eni_ips" {
  value = "${module.bootstrap_es.eni_ips}"
}

output "bind_eip_ips" {
  value = "${module.bootstrap_es.public_ips}"
}
