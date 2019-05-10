provider "aws" {
  region  = "${var.region}"
}

module "providers" {
  source = "../../../../../modules/dark_providers"
}

variable "volume_id" {
  description = "volume ID to create AMI from"
}
variable "region" {
  default = "us-east-1"
  description = "AWS region"
}
variable "naming_prefix" {
  description = "prefix for MJB AMI naming"
  default = ""
}

module "exporter" {
  source="../../../../../modules/volume_to_ami"
  ami_name = "${var.naming_prefix}${replace("MJB-${timestamp()}",":",".")}"
  volume_id = "${var.volume_id}"
  region = "${var.region}"
}

output "ami_id" {
  value = "${module.exporter.ami_id}"
}
