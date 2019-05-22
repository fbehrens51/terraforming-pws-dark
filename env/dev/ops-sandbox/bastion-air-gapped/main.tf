terraform {
  backend "s3" {
    bucket         = "eagle-state"
    key            = "dev/bastion-air-gapped/terraform.tfstate"
    encrypt        = true
    kms_key_id     = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
    dynamodb_table = "bastion-air-gapped-state"
    region         = "us-east-1"
  }
}

locals {
  vpc_cidr          = "10.0.0.0/24"
  region            = "us-east-1"
  availability_zone = "us-east-1a"

  //hack to fix the path for windows, theoretically this will be fixed in v 0.12 to use same convention on all OS
  module_path = "${replace(path.module, "\\", "/")}"

  local_user_data_path = "${local.module_path}/other.yml"

  inbound_customer_required = {
    "443" = ["0.0.0.100/30", "0.0.1.0/28"]

    "8080" = ["0.0.0.128/26", "0.0.10.0/24"]
  }

  inbound_ssh_cidrs = ["0.0.0.0/0"]

  customer_ingress = {
    "443" = ["0.0.0.100/30", "0.0.1.0/28"]

    "8080" = ["0.0.0.128/26", "0.0.10.0/24"]
  }

  tags = {
    Name = "air-gapped bastion"
  }
}

provider "aws" {
  region = "us-east-1"
}

module "providers" {
  source = "../../../../modules/dark_providers"
}

// pre-reqs

resource "aws_vpc" "vpc" {
  cidr_block = "${local.vpc_cidr}"
  tags       = "${local.tags}"
}

resource "aws_eip" "eip" {
  tags = "${local.tags}"
}

resource "aws_internet_gateway" "ig" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags   = "${local.tags}"
}

//use case

module "bootstrap_bastion" {
  source            = "../../../../modules/bastion/bootstrap"
  vpc_id            = "${aws_vpc.vpc.id}"
  gateway_id        = "${aws_internet_gateway.ig.id}"
  availability_zone = "${local.availability_zone}"
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = "${module.bastion_host.bastion_instance_id}"
  allocation_id = "${aws_eip.eip.id}"
}

data "template_cloudinit_config" "user_data" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "other.cfg"
    content_type = "text/cloud-config"
    content      = "${file("${local.local_user_data_path}")}"
  }
}

module "bastion_groups" {
  source           = "../../../../modules/bastion/security_group"
  customer_ingress = "${local.customer_ingress}"
  ssh_cidrs        = "${local.inbound_ssh_cidrs}"
  vpc_id           = "${aws_vpc.vpc.id}"
}

module "amazon_ami" {
  source = "../../../../modules/amis/amazon_hvm_ami"
  region = "${local.region}"
}

module "bastion_host" {
  source             = "../../../../modules/bastion/launch_bastion_airgapped"
  ami_id             = "${module.amazon_ami.id}"
  user_data          = "${data.template_cloudinit_config.user_data.rendered}"
  subnet_id          = "${module.bootstrap_bastion.public_subnet_id}"
  security_group_ids = ["${module.bastion_groups.bastion_security_group_id}"]
}
