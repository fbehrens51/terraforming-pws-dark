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

  //allow dns to reach out anywhere. This is needed for CNAME records to external DNS
  bind_egress_rules = [
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

  bind_ingress_rules = [
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

  # TODO: what should this be
  splunk_ingress_rules = [
    {
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port        = "8088"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port        = "8089"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port        = "8000"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port        = "8090"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  splunk_egress_rules = [
    {
      port        = "0"
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  splunk_volume_tag = "${var.env_name}-SPLUNK_DATA"

  ldap_ingress_rules = [
    {
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port        = "636"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  ldap_egress_rules = [
    {
      port        = "0"
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  bind_cidr_block   = "${cidrsubnet(data.aws_vpc.this_vpc.cidr_block, 2, 0)}"
  ldap_cidr_block   = "${cidrsubnet(data.aws_vpc.this_vpc.cidr_block, 2, 1)}"
  splunk_cidr_block = "${cidrsubnet(data.aws_vpc.this_vpc.cidr_block, 2, 2)}"
}

data "aws_vpc" "this_vpc" {
  id = "${local.es_vpc_id}"
}

module "bootstrap_es" {
  source             = "../../modules/multiple_subnet_vpc"
  availability_zones = "${var.availability_zones}"
  vpc_id             = "${local.es_vpc_id}"
  cidr_block         = "${local.bind_cidr_block}"
  route_table_id     = "${data.terraform_remote_state.routes.es_public_vpc_route_table_id}"
  ingress_rules      = ["${local.bind_ingress_rules}"]
  egress_rules       = ["${local.bind_egress_rules}"]
  tags               = "${local.modified_tags}"
  create_eip         = true
}

module "bootstrap_ldap" {
  source            = "../../modules/single_use_subnet"
  cidr_block        = "${local.ldap_cidr_block}"
  availability_zone = "${var.singleton_availability_zone}"
  route_table_id    = "${data.terraform_remote_state.routes.es_public_vpc_route_table_id}"
  ingress_rules     = "${local.ldap_ingress_rules}"
  egress_rules      = "${local.ldap_egress_rules}"
  tags              = "${local.modified_tags}"
  create_eip        = true
}

module "bootstrap_splunk" {
  source            = "../../modules/single_use_subnet"
  cidr_block        = "${local.splunk_cidr_block}"
  availability_zone = "${var.singleton_availability_zone}"
  route_table_id    = "${data.terraform_remote_state.routes.es_public_vpc_route_table_id}"
  ingress_rules     = "${local.splunk_ingress_rules}"
  egress_rules      = "${local.splunk_egress_rules}"
  tags              = "${local.modified_tags}"
  create_eip        = true
}

module "amazon_ami" {
  source = "../../modules/amis/amazon_hvm_ami"
  region = "${var.region}"
}

resource "aws_ebs_volume" "splunk_data" {
  availability_zone = "${var.singleton_availability_zone}"
  size              = 1000

  tags {
    Name = "${local.splunk_volume_tag}"
  }
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

output "ldap_eni_id" {
  value = "${module.bootstrap_ldap.eni_id}"
}

output "ldap_public_subnet_id" {
  value = "${module.bootstrap_ldap.public_subnet_id}"
}

output "ldap_private_ip" {
  value = "${module.bootstrap_ldap.private_ip}"
}

output "ldap_public_ip" {
  value = "${module.bootstrap_ldap.public_ips[0]}"
}

output "splunk_eni_id" {
  value = "${module.bootstrap_splunk.eni_id}"
}

output "splunk_public_ip" {
  value = "${module.bootstrap_splunk.public_ips}"
}

output "splunk_private_ip" {
  value = "${module.bootstrap_splunk.private_ip}"
}

output "splunk_volume_tag" {
  value = "${local.splunk_volume_tag}"
}

output "splunk_subnet_id" {
  value = "${module.bootstrap_splunk.public_subnet_id}"
}

output "splunk_subnet_cidr" {
  value = "${module.bootstrap_splunk.cidr_block}"
}
