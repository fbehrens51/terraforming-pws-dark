data "aws_vpc" "vpc" {
  id = "${var.vpc_id}"
}

resource "aws_internet_gateway" "ig" {
  vpc_id = "${data.aws_vpc.vpc.id}"
  tags = "${merge(var.tags, map("Name", "${var.name_prefix}-igw"))}"
}

resource "aws_route_table" "public_route_table" {
  vpc_id = "${data.aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ig.id}"
  }
}

resource "aws_route_table_association" "route_public_subnets" {
  count          = "${length(var.availability_zones)}"
  subnet_id      = "${element(var.public_subnets, count.index)}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

variable "name_prefix" {
}

variable "tags" {
  type = "map"
}

variable "availability_zones" {
  type = "list"
}

variable "public_subnets" {
  type = "list"
}

variable "vpc_id" {
  type = "string"
}

output "gateway_id" {
  value = "${aws_internet_gateway.ig.id}"
}