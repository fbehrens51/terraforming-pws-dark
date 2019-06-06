resource "aws_security_group" "nat_security_group" {
  count = "${var.internetless ? 0 : 1}"

  name        = "nat_security_group"
  description = "NAT Security Group"
  vpc_id      = "${data.aws_vpc.vpc.id}"

  ingress {
    cidr_blocks = ["${data.aws_vpc.vpc.cidr_block}"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  tags = "${merge(var.tags, map("Name", "${var.env_name}-nat-security-group"))}"
}

resource "aws_nat_gateway" "nat" {
  count         = "${var.internetless ? 0 : 1}"
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${element(aws_subnet.public_subnets.*.id, 0)}"

  tags = "${merge(var.tags, map("Name", "${var.env_name}-nat"))}"
}

resource "aws_eip" "nat_eip" {
  count = "${var.internetless ? 0 : 1}"

  vpc = true

  tags = "${var.tags}"
}

resource "aws_route" "toggle_internet" {
  count = "${var.internetless ? 0 : 1}"

  route_table_id         = "${var.private_route_table_id}"
  nat_gateway_id         = "${aws_nat_gateway.nat.id}"
  destination_cidr_block = "0.0.0.0/0"
}
