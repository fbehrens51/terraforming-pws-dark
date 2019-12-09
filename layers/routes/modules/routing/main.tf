variable "requester_vpc_id" {}
variable "accepter_vpc_id" {}

variable "requester_route_table_ids" {
  type = "list"
}

variable "accepter_route_table_ids" {
  type = "list"
}

variable "availability_zones" {
  type = "list"
}

data "aws_vpc" "accepter_vpc" {
  id = "${var.accepter_vpc_id}"
}

data "aws_vpc" "requester_vpc" {
  id = "${var.requester_vpc_id}"
}

data "aws_vpc_peering_connection" "peering_connection" {
  vpc_id      = "${var.requester_vpc_id}"
  peer_vpc_id = "${var.accepter_vpc_id}"
}

data "aws_route_tables" "accepter_route_table" {
  vpc_id = "${var.accepter_vpc_id}"

  filter {
    name   = "route-table-id"
    values = ["${var.accepter_route_table_ids}"]
  }
}

data "aws_route_tables" "requester_route_table" {
  vpc_id = "${var.requester_vpc_id}"

  filter {
    name   = "route-table-id"
    values = ["${var.requester_route_table_ids}"]
  }
}

resource "aws_route" "route_to_add_to_accepter" {
  count                     = "${length(var.availability_zones) + 1}"
  route_table_id            = "${element(data.aws_route_tables.accepter_route_table.ids, count.index)}"
  destination_cidr_block    = "${data.aws_vpc.requester_vpc.cidr_block}"
  vpc_peering_connection_id = "${data.aws_vpc_peering_connection.peering_connection.id}"

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "route_to_add_to_requestor" {
  count                     = "${length(var.availability_zones) + 1}"
  route_table_id            = "${element(data.aws_route_tables.requester_route_table.ids, count.index)}"
  destination_cidr_block    = "${data.aws_vpc.accepter_vpc.cidr_block}"
  vpc_peering_connection_id = "${data.aws_vpc_peering_connection.peering_connection.id}"

  timeouts {
    create = "5m"
  }
}
