variable "requester_vpc_id" {}
variable "accepter_vpc_id" {}

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
}

data "aws_route_tables" "requester_route_table" {
  vpc_id = "${var.requester_vpc_id}"
}

resource "aws_route" "route_to_add_to_accepter" {
  count = "${length(data.aws_route_tables.accepter_route_table.ids)}"

  route_table_id            = "${element(data.aws_route_tables.accepter_route_table.ids, count.index)}"
  destination_cidr_block    = "${data.aws_vpc.requester_vpc.cidr_block}"
  vpc_peering_connection_id = "${data.aws_vpc_peering_connection.peering_connection.id}"

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "route_to_add_to_requestor" {
  count = "${length(data.aws_route_tables.requester_route_table.ids)}"

  route_table_id            = "${element(data.aws_route_tables.requester_route_table.ids, count.index)}"
  destination_cidr_block    = "${data.aws_vpc.accepter_vpc.cidr_block}"
  vpc_peering_connection_id = "${data.aws_vpc_peering_connection.peering_connection.id}"

  timeouts {
    create = "5m"
  }
}
