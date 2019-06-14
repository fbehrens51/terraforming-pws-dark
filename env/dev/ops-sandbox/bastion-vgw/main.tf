terraform {
  backend "s3" {
    bucket         = "eagle-state"
    key            = "dev/bastion-vgw/terraform.tfstate"
    encrypt        = true
    kms_key_id     = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
    dynamodb_table = "bastion-vgw-state"
    region         = "us-east-1"
  }
}

locals {
  vpc_cidr          = "10.60.0.0/23"
  region            = "us-east-1"
  availability_zone = "us-east-1a"

  //hack to fix the path for windows, theoretically this will be fixed in v 0.12 to use same convention on all OS
  module_path = "${replace(path.module, "\\", "/")}"

  local_user_data_path = "${local.module_path}/other.yml"

  ingress_rules = [
    {
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_rules = [
    {
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port        = "80"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags = {
    Name = "vgw bastion"
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

resource "aws_vpn_gateway" "ig" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags   = "${local.tags}"
}

// use case

module "bootstrap_bastion" {
  source            = "../../../../modules/single_use_subnet"
  availability_zone = "${local.availability_zone}"
  route_table_id    = "${aws_vpc.vpc.default_route_table_id}"
  ingress_rules     = "${local.ingress_rules}"
  egress_rules      = "${local.egress_rules}"
  tags              = "${local.tags}"
  create_eip        = false
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

module "amazon_ami" {
  source = "../../../../modules/amis/amazon_hvm_ami"
  region = "${local.region}"
}

module "bastion_host" {
  source    = "../../../../modules/launch"
  ami_id    = "${module.amazon_ami.id}"
  user_data = "${data.template_cloudinit_config.user_data.rendered}"
  eni_ids   = ["${module.bootstrap_bastion.eni_id}"]
  tags      = "${local.tags}"
}
