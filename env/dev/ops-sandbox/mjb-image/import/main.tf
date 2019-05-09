terraform {
  backend "s3" {
    bucket = "eagle-state"
    key = "dev/mjb-import/terraform.tfstate"
    encrypt = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
    dynamodb_table = "mjb-import"
  }
}

locals {
  external_cidr_blocks = ["0.0.0.0/0"]
  importer_vm_instance_profile = "DIRECTOR"
  s3_object_key = "mjb-1556914317.img.tgz"
  region="us-east-1"
}

variable "subnet_id" {}

provider "aws" {
  region  = "${local.region}"
}

module "providers" {
  source = "../../../../../modules/dark_providers"
}

data "aws_subnet" "importer_subnet" {
  id = "${var.subnet_id}"
}

data "aws_vpc" "current_vpc" {
  id = "${data.aws_subnet.importer_subnet.vpc_id}"
}

//creation of group
module "importer_sg" {
  source = "../../../../../modules/importer_security_group/create"
  vpc_id = "${data.aws_vpc.current_vpc.id}"
  external_cidr_blocks = "${local.external_cidr_blocks}"
}

module "amazon_hvm_ami" {
  source = "../../../../../modules/amis/amazon_hvm_ami"
  region = "${local.region}"
}

module "MJB_import" {
  source = "../../../../../modules/s3_image_tgz_to_volume"
  bucket_name = "jumpbox-images"
  s3_object_key = "${local.s3_object_key}"
  region = "${local.region}"
  subnet_id = "${var.subnet_id}"
  ami_id = "${module.amazon_hvm_ami.id}"
  security_group_ids = ["${module.importer_sg.id}"]
  enable_public_ip = "true"
  iam_instance_profile = "${local.importer_vm_instance_profile}"
  //to improve copy of image to volume, extraction of image to volume, and snapshot, beef up instance to one with higher bandwidth, throughput, and IOPs
  instance_type = "m4.16xlarge"

}

output "volume_id" {
  value = "${module.MJB_import.volume_id}"
}
