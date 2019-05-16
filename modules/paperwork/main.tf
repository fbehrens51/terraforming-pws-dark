variable "vpc_cidr" {}

variable "tags" {
  type = "map"
}

locals {
  suffix = "${random_integer.suffix.result}"
  director_role_name = "DIRECTOR-${local.suffix}"
  bucket_role_name = "pas-om-bucket-role-${local.suffix}"
}

module "key" {
  source = "../kms/create"
  key_name = "pas_kms_key_${local.suffix}"
}

module "iam" {
  source = "./iam"
  director_role_name = "${local.director_role_name}"
  bucket_role_name = "${local.bucket_role_name}"
}

resource "random_integer" "suffix" {
  min = 1
  max = 100000
}

resource "aws_vpc" "vpc" {
  cidr_block = "${var.vpc_cidr}"
  tags = "${var.tags}"
}

resource "aws_internet_gateway" "ig" {
  vpc_id = "${aws_vpc.vpc.id}"
}

output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "ig_id" {
  value = "${aws_internet_gateway.ig.id}"
}

output "key_id" {
  value = "${module.key.kms_key_id}"
}

output "director_role_name" {
  value = "${local.director_role_name}"
}

output "bucket_role_name" {
  value = "${local.bucket_role_name}"
}

output "bucket_role_arn" {
  value = "${module.iam.bucket_role_arn}"
}
