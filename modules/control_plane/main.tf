variable "vpc_id" {
  description = "Control Plane VPC ID"
}

variable "availability_zone" {
  description = "AZ, specify or will default to first in list of available"
  default = ""
}

variable "gateway_id" {}

variable "ingress_cidr_blocks" {
  type = "list"
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
  availability_zone = "${var.availability_zone !="" ? var.availability_zone : data.aws_availability_zones.available.names[0]}"
}

resource "aws_subnet" "public_subnet" {
  cidr_block = "${local.public_subnet_cidr}"
  vpc_id = "${var.vpc_id}"
  availability_zone = "${local.availability_zone}"
  tags {
    Name = "Control Plane public subnet"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = "${var.vpc_id}"
  tags {
    Name="CP Public Route Table"
  }
}

resource "aws_route" "route_to_gw" {
  route_table_id = "${aws_route_table.public_route_table.id}"
  gateway_id = "${var.gateway_id}"
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "route_public_subnet" {
  subnet_id = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

resource "aws_security_group" "mjb_security_group" {
  name_prefix = "mjb-sg"
  vpc_id = "${var.vpc_id}"

  tags {
    Name="mjb-sg"
  }
}

resource "aws_security_group_rule" "ingress_ssh" {
  from_port = 22
  protocol = "tcp"
  security_group_id = "${aws_security_group.mjb_security_group.id}"
  to_port = 22
  type = "ingress"
  cidr_blocks = ["${var.ingress_cidr_blocks}"]
}

resource "aws_security_group_rule" "egress_everywhere" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.mjb_security_group.id}"
}

output "public_subnet_id" {
  value = "${aws_subnet.public_subnet.id}"
}

output "mjb_security_group_id" {
  value = "${aws_security_group.mjb_security_group.id}"
}
