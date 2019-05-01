locals {
  vpc_id="vpc-00525b6ff996566ac"
  region="us-east-1"
  availability_zones=["us-east-1a"]
  //hack to fix the path for windows, theoretically this will be fixed in v 0.12 to use same convention on all OS
  module_path = "${replace(path.module, "\\", "/")}"
  local_user_data_path      = "${local.module_path}/other.yml"
  peering_connection_ids = ["pcx-09b5f5a68ef486f47","pcx-00a4c3b08e90325a4","pcx-08c628d99069a37b6"]
  inbound_ssh_cidrs = ["0.0.0.0/0"]
}

provider "aws" {
  region     = "us-east-1"
  version = "<=1.50"
}
provider "template" {
  version = "~> 2.0"
}

resource "aws_internet_gateway" "ig" {
  vpc_id = "${local.vpc_id}"
  tags = {
    Name = "Bastion IGW"
  }
}

module "bootstrap_bastion" {
  source = "../../../../modules/bastion/bootstrap"
  vpc_id = "${local.vpc_id}"
  gateway_id = "${aws_internet_gateway.ig.id}"
  peering_connection_ids = "${local.peering_connection_ids}"
}

data "template_cloudinit_config" "user_data" {
  base64_encode = false
  gzip = false
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
  source = "../../../../modules/bastion/launch_bastion_instance"
  ami_id = "${module.amazon_ami.id}"
  user_data = "${data.template_cloudinit_config.user_data.rendered}"
  subnet_id = "${module.bootstrap_bastion.public_subnet_id}"
  enable_public_ip = "true"
  ssh_cidrs = "${local.inbound_ssh_cidrs}"
}

