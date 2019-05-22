variable "requester_route_table_id" {}
variable "accepter_route_table_id" {}

data "aws_vpc_peering_connection" "peering_connection" {
  vpc_id      = "${data.aws_vpc.requester_vpc.id}"
  peer_vpc_id = "${data.aws_vpc.accepter_vpc.id}"
}

data "aws_route_table" "accepter_route_table" {
  route_table_id = "${var.accepter_route_table_id}"
}

data "aws_route_table" "requester_route_table" {
  route_table_id = "${var.requester_route_table_id}"
}

data "aws_vpc" "accepter_vpc" {
  id = "${data.aws_route_table.accepter_route_table.vpc_id}"
}

data "aws_vpc" "requester_vpc" {
  id = "${data.aws_route_table.requester_route_table.vpc_id}"
}

resource "aws_route" "route_to_add_to_accepter" {
  route_table_id            = "${var.accepter_route_table_id}"
  destination_cidr_block    = "${data.aws_vpc.requester_vpc.cidr_block}"
  vpc_peering_connection_id = "${data.aws_vpc_peering_connection.peering_connection.id}"
}

resource "aws_route" "route_to_add_to_requestor" {
  route_table_id            = "${var.requester_route_table_id}"
  destination_cidr_block    = "${data.aws_vpc.accepter_vpc.cidr_block}"
  vpc_peering_connection_id = "${data.aws_vpc_peering_connection.peering_connection.id}"
}
