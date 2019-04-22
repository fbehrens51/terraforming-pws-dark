resource "aws_vpc" "vpc" {
  cidr_block           = "${var.vpc_cidr}"
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = "${merge(var.tags, map("Name", "${var.name_prefix}-vpc"))}"
}

variable "name_prefix" {
}

variable "tags" {
  type = "map"
}

variable "vpc_cidr" {
  type = "string"
}

output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}