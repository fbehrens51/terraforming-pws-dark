variable "vpc_id" {}

variable "tags" {
  type = "map"
}

locals {
  env_name    = "${var.tags["Name"]}"
  public_name = "${local.env_name} PUBLIC"
  public_tags = "${merge(var.tags, map("Name", "${local.public_name}"))}"

  private_name = "${local.env_name} PRIVATE"
  private_tags = "${merge(var.tags, map("Name", "${local.private_name}"))}"
}

variable "internetless" {}

data "aws_internet_gateway" "igw" {
  count = "${var.internetless ? 0 : 1}"

  filter {
    name   = "attachment.vpc-id"
    values = ["${var.vpc_id}"]
  }
}

data "aws_vpn_gateway" "vgw" {
  count = "${var.internetless ? 1 : 0}"

  attached_vpc_id = "${var.vpc_id}"
}

resource "aws_route" "default_route" {
  route_table_id         = "${aws_route_table.public_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${element(concat(data.aws_internet_gateway.igw.*.internet_gateway_id, data.aws_vpn_gateway.vgw.*.id), 0)}"

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table" "public_route_table" {
  count = 1

  vpc_id = "${var.vpc_id}"

  tags = "${local.public_tags}"
}

resource "aws_route_table" "private_route_table" {
  count = 1

  vpc_id = "${var.vpc_id}"

  tags = "${local.private_tags}"
}

output "public_route_table_id" {
  value = "${element(concat(aws_route_table.public_route_table.*.id, list("")), 0)}"
}

output "private_route_table_id" {
  value = "${element(concat(aws_route_table.private_route_table.*.id, list("")), 0)}"
}
