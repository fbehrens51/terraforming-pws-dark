variable "vpc_id" {}

variable "availability_zones" {
  type = "list"
}

variable "route_table_id" {}

variable "ingress_rules" {
  type = "list"
}

variable "egress_rules" {
  type = "list"
}

data "aws_vpc" "this_vpc" {
  id = "${var.vpc_id}"
}

variable "tags" {
  type = "map"
}

variable "create_eip" {}

variable "newbits" {
  default = "4"
}

module "subnets" {
  source            = "subnet_per_az"
  availablity_zones = "${var.availability_zones}"
  cidr_block        = "${data.aws_vpc.this_vpc.cidr_block}"
  newbits           = "${var.newbits}"
  tags              = "${var.tags}"
  vpc_id            = "${var.vpc_id}"
}

resource "aws_route_table_association" "route_public_subnet" {
  count          = "${length(var.availability_zones)}"
  subnet_id      = "${module.subnets.subnet_ids[count.index]}"
  route_table_id = "${var.route_table_id}"
}

module "security_group" {
  source        = "../single_use_subnet/security_group"
  ingress_rules = "${var.ingress_rules}"
  egress_rules  = "${var.egress_rules}"
  tags          = "${var.tags}"
  vpc_id        = "${var.vpc_id}"
}

resource "aws_network_interface" "eni" {
  count     = "${length(var.availability_zones)}"
  subnet_id = "${module.subnets.subnet_ids[count.index]}"

  security_groups = [
    "${module.security_group.security_group_id}",
  ]

  tags = "${var.tags}"
}

resource "aws_eip" "eip" {
  count = "${var.create_eip ? length(var.availability_zones) : 0}"
  vpc   = true
  tags  = "${var.tags}"
}

output "subnet_ids" {
  value = "${module.subnets.subnet_ids}"
}

output "subnet_cidr_blocks" {
  value = "${module.subnets.subnet_cidr_blocks}"
}

output "public_ips" {
  value = "${aws_eip.eip.*.public_ip}"
}

output "eip_ids" {
  value = "${aws_eip.eip.*.id}"
}

output "eni_ids" {
  value = "${aws_network_interface.eni.*.id}"
}

output "eni_ips" {
  value = "${aws_network_interface.eni.*.private_ip}"
}
