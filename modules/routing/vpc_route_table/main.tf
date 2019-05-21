variable "vpc_id" {}

variable "tags" {
  type = "map"
}

data "aws_internet_gateway" "pas_igw" {
  filter {
    name = "attachment.vpc-id"
    values = ["${var.vpc_id}"]
  }
}

resource "aws_route" "pas_default_route" {
  route_table_id = "${aws_route_table.pas_public_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${data.aws_internet_gateway.pas_igw.internet_gateway_id}"
}

resource "aws_route_table" "pas_public_route_table" {
  vpc_id = "${var.vpc_id}"
  tags = "${var.tags}"
}

output "route_table_id" {
  value = "${aws_route_table.pas_public_route_table.id}"
}