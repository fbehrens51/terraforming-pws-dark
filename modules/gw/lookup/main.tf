data "aws_vpc" "vpc" {
  id = "${var.vpc_id}"
}

resource "aws_route_table" "public_route_table" {
  vpc_id = "${data.aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${var.gateway_id}"
  }
}

resource "aws_route_table_association" "route_public_subnets" {
  count          = "${length(var.availability_zones)}"
  subnet_id      = "${element(var.public_subnets, count.index)}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

variable "availability_zones" {
  type = "list"
}

variable "public_subnets" {
  type = "list"
}

variable "gateway_id" {
  type = "string"
}

variable "vpc_id" {
  type = "string"
}
