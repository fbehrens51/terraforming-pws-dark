locals {
  newbits = "${ceil(log(length(var.availability_zones), 2))}"
}

resource "aws_subnet" "rds_subnets" {
  count             = "${length(var.availability_zones)}"
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${cidrsubnet(var.cidr_block, local.newbits, count.index)}"
  availability_zone = "${element(var.availability_zones, count.index)}"

  tags = "${merge(var.tags, map("Name", "${var.env_name}-rds-subnet${count.index}"))}"
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = "${var.env_name}_db_subnet_group"
  description = "RDS Subnet Group"

  subnet_ids = ["${aws_subnet.rds_subnets.*.id}"]

  tags = "${merge(var.tags, map("Name", "${var.env_name}-db-subnet-group"))}"
}
