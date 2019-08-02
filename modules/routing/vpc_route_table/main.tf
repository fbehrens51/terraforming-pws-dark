variable "vpc_id" {}

variable "tags" {
  type = "map"
}

variable "internetless" {}

data "aws_internet_gateway" "pas_igw" {
  count = "${var.internetless ? 0 : 1}"

  filter {
    name   = "attachment.vpc-id"
    values = ["${var.vpc_id}"]
  }
}

data "aws_vpn_gateway" "pas_vgw" {
  count = "${var.internetless ? 1 : 0}"

  attached_vpc_id = "${var.vpc_id}"
}

resource "aws_route" "pas_default_route" {
  route_table_id         = "${aws_route_table.pas_public_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${element(concat(data.aws_internet_gateway.pas_igw.*.internet_gateway_id, data.aws_vpn_gateway.pas_vgw.*.id), 0)}"
}

resource "aws_route_table" "pas_public_route_table" {
  vpc_id = "${var.vpc_id}"
  tags   = "${var.tags}"
}

output "route_table_id" {
  value = "${aws_route_table.pas_public_route_table.id}"
}
