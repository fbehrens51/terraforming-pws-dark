# Bosh Director Subnet
resource "aws_subnet" "infrastructure_subnets" {
  count             = "${length(var.availability_zones)}"
  vpc_id            = "${data.aws_vpc.vpc.id}"
  cidr_block        = "${cidrsubnet(local.infrastructure_cidr, 2, count.index)}"
  availability_zone = "${element(var.availability_zones, count.index)}"

  tags = "${merge(var.tags, map("Name", "${var.env_name}-infrastructure-subnet${count.index}"))}"
}

resource "aws_subnet" "om_subnets" {
  count             = "${length(var.availability_zones)}"
  vpc_id            = "${data.aws_vpc.vpc.id}"
  cidr_block        = "${cidrsubnet(local.om_cidr, 2, count.index)}"
  availability_zone = "${element(var.availability_zones, count.index)}"

  tags = "${merge(var.tags, map("Name", "${var.env_name}-om-subnet${count.index}"))}"
}

data "template_file" "infrastructure_subnet_gateways" {
  # Render the template once for each availability zone
  count    = "${length(var.availability_zones)}"
  template = "$${gateway}"

  vars {
    gateway = "${cidrhost(element(aws_subnet.infrastructure_subnets.*.cidr_block, count.index), 1)}"
  }
}

data "template_file" "om_subnet_gateways" {
  # Render the template once for each availability zone
  count    = "${length(var.availability_zones)}"
  template = "$${gateway}"

  vars {
    gateway = "${cidrhost(element(aws_subnet.om_subnets.*.cidr_block, count.index), 1)}"
  }
}

resource "aws_route_table_association" "route_om_subnets" {
  count          = "${length(var.availability_zones)}"
  route_table_id = "${var.private_route_table_id}"
  subnet_id      = "${element(aws_subnet.om_subnets.*.id, count.index)}"
}

resource "aws_route_table_association" "route_infrastructure_subnets" {
  count          = "${length(var.availability_zones)}"
  route_table_id = "${var.private_route_table_id}"
  subnet_id      = "${element(aws_subnet.infrastructure_subnets.*.id, count.index)}"
}

resource "aws_subnet" "public_subnets" {
  count             = "${length(var.availability_zones)}"
  vpc_id            = "${data.aws_vpc.vpc.id}"
  cidr_block        = "${cidrsubnet(local.public_cidr, 2, count.index)}"
  availability_zone = "${element(var.availability_zones, count.index)}"

  tags = "${merge(var.tags, map("Name", "${var.env_name}-public-subnet${count.index}"),
      map("kubernetes.io/role/elb", "1"),
      map("SubnetType", "Utility"))}"

  # Ignore additional tags that are added for specifying clusters.
  lifecycle {
    ignore_changes = ["tags.%", "tags.kubernetes"]
  }
}

resource "aws_route_table_association" "public_subnet_route_table_assoc" {
  count          = "${length(var.availability_zones)}"
  route_table_id = "${var.public_route_table_id}"
  subnet_id      = "${element(aws_subnet.public_subnets.*.id,count.index)}"
}
