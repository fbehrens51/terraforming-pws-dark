terraform {
  backend "s3" {
    bucket = "eagle-state"
    key = "dev/cp-vgw/terraform.tfstate"
    encrypt = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
    dynamodb_table = "cp-vgw-state"
    region = "us-east-1"
  }
}

locals {
  env_name = "vgw control plane"
  instance_type = "m4.xlarge"
  instance_profile = "DIRECTOR"
  user_data_file = "${path.module}/user_data.yml"
  enable_public_ip = true
  vpc_cidr = "10.160.0.0/24"
  availability_zone = "us-east-1a"
  external_cidr_blocks = ["72.83.230.85/32", "0.0.0.0/0"]
}

provider "aws" {
  region = "us-east-1"
}

module "dark_providers" {
  source = "../../../../modules/dark_providers"
}

// pre-reqs

resource "aws_vpc" "vpc" {
  cidr_block = "${local.vpc_cidr}"
  tags = "${var.tags}"
}

resource "aws_internet_gateway" "ig" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = "${var.tags}"
}

// use case

variable "tags" {
  type = "map"
  default = {
    "Name" = "control plane vgw"
  }
}

resource "aws_key_pair" "mjb_key_pair" {
  key_name   = "${local.env_name} mjb key"
  public_key = "${tls_private_key.mjb_private_key.public_key_openssh}"
}

resource "tls_private_key" "mjb_private_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

module "bootstrapper" {
  source = "../../../../modules/control_plane"
  gateway_id = "${aws_internet_gateway.ig.id}"
  vpc_id = "${aws_vpc.vpc.id}"
  availability_zone = "${local.availability_zone}"
  ingress_cidr_blocks = "${local.external_cidr_blocks}"
}

module "find_mjb_ami" {
  source = "../../../../modules/master-jump-box/lookup-ami"
}

module "mjb_instance" {
  source = "../../../../modules/master-jump-box/launch"
  ami_id = "${module.find_mjb_ami.id}"
  instance_type = "${local.instance_type}"
  subnet_id = "${module.bootstrapper.public_subnet_id}"
  instance_profile = "${local.instance_profile}"
  security_group_id = "${module.bootstrapper.mjb_security_group_id}"
  user_data_yml = "${local.user_data_file}"
  enable_public_ip = "${local.enable_public_ip}"
  key_name = "${aws_key_pair.mjb_key_pair.key_name}"
}

output "mjb_private_key" {
  value = "${tls_private_key.mjb_private_key.private_key_pem}"
}

output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "subnet_id" {
  value = "${module.bootstrapper.public_subnet_id}"
}

output "mjb_security_group_id" {
  value = "${module.bootstrapper.mjb_security_group_id}"
}
