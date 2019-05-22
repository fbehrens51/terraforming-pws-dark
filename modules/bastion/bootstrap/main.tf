variable "vpc_id" {
  description = "Bastion Plane VPC ID"
}

variable "availability_zone" {
  description = "AZ, specify or will default to first in list of available"
  default     = ""
}

variable "gateway_id" {}

variable "peering_connection_ids" {
  type    = "list"
  default = []
}

data "aws_vpc" "cp_vpc" {
  id = "${var.vpc_id}"
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  //TODO: move to a module to support varying sizes of cidrs (currently expecting /24)
  public_subnet_cidr = "${cidrsubnet(data.aws_vpc.cp_vpc.cidr_block,4,0)}"
  availability_zone  = "${var.availability_zone !="" ? var.availability_zone : data.aws_availability_zones.available.names[0]}"
}

resource "aws_subnet" "public_subnet" {
  cidr_block        = "${local.public_subnet_cidr}"
  vpc_id            = "${var.vpc_id}"
  availability_zone = "${local.availability_zone}"

  tags {
    Name = "Bastion public subnet"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = "${var.vpc_id}"
}

resource "aws_route" "route_to_gw" {
  route_table_id         = "${aws_route_table.public_route_table.id}"
  gateway_id             = "${var.gateway_id}"
  destination_cidr_block = "0.0.0.0/0"
}

data "aws_vpc_peering_connection" "peering_connections" {
  count = "${length(var.peering_connection_ids)}"
  id    = "${element(var.peering_connection_ids, count.index)}"
}

resource "aws_route" "peering_connection_route" {
  count                     = "${length(var.peering_connection_ids)}"
  route_table_id            = "${aws_route_table.public_route_table.id}"
  vpc_peering_connection_id = "${element(var.peering_connection_ids, count.index)}"
  destination_cidr_block    = "${data.aws_vpc_peering_connection.peering_connections.*.peer_cidr_block[count.index]}"
}

resource "aws_route_table_association" "route_public_subnet" {
  subnet_id      = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

output "public_subnet_id" {
  value = "${aws_subnet.public_subnet.id}"
}
