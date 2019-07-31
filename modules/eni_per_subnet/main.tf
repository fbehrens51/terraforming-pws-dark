variable "ingress_rules" {
  type = "list"
}

variable "egress_rules" {
  type = "list"
}

variable "subnet_ids" {
  type = "list"
}

variable "tags" {
  type = "map"
}

variable "create_eip" {}

data "aws_subnet" "first_subnet" {
  id = "${var.subnet_ids[0]}"
}

module "security_group" {
  source        = "../single_use_subnet/security_group"
  ingress_rules = "${var.ingress_rules}"
  egress_rules  = "${var.egress_rules}"
  tags          = "${var.tags}"
  vpc_id        = "${data.aws_subnet.first_subnet.vpc_id}"
}

resource "aws_network_interface" "eni" {
  count     = "${length(var.subnet_ids)}"
  subnet_id = "${var.subnet_ids[count.index]}"

  security_groups = [
    "${module.security_group.security_group_id}",
  ]

  tags = "${var.tags}"
}

resource "aws_eip" "eip" {
  count = "${var.create_eip ? length(var.subnet_ids) : 0}"
  vpc   = true
  tags  = "${var.tags}"
}

resource "aws_eip_association" "eip_association" {
  count                = "${var.create_eip ? length(var.subnet_ids) : 0}"
  network_interface_id = "${element(aws_network_interface.eni.*.id, count.index)}"
  allocation_id        = "${element(aws_eip.eip.*.id, count.index)}"
}

output "public_ips" {
  value = "${aws_eip.eip.*.public_ip}"
}

# output "eip_ids" {
#   value = "${aws_eip.eip.*.id}"
# }

output "eni_ids" {
  value = "${aws_network_interface.eni.*.id}"
}

output "eni_ips" {
  value = "${aws_network_interface.eni.*.private_ip}"
}
