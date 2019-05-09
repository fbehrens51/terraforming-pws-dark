variable "vpc_id" {}

variable "ssh_cidrs" {
  type = "list"
}

variable "customer_ingress" {
  type = "map"
}

resource "aws_security_group" "bastion_security_group" {
  name_prefix = "bastion_sg-"
  vpc_id = "${var.vpc_id}"
  tags {
    Name="bastion-sg"
  }
}

resource "aws_security_group_rule" "ssh_ingress" {
  from_port = 22
  protocol = "tcp"
  security_group_id = "${aws_security_group.bastion_security_group.id}"
  to_port = 22
  type = "ingress"
  cidr_blocks = ["${var.ssh_cidrs}"]
  depends_on = ["aws_security_group.bastion_security_group"]
}

resource "aws_security_group_rule" "ssh_egress" {
  from_port = 22
  protocol = "tcp"
  security_group_id = "${aws_security_group.bastion_security_group.id}"
  to_port = 22
  type = "egress"
  cidr_blocks = ["0.0.0.0/0"]
  depends_on = ["aws_security_group.bastion_security_group"]
}

resource "aws_security_group_rule" "customer_ingress" {
  count = "${length (var.customer_ingress)}"

  from_port = "${element(keys(var.customer_ingress), count.index)}"
  to_port = "${element(keys(var.customer_ingress), count.index)}"

  cidr_blocks = ["${var.customer_ingress[element(keys(var.customer_ingress), count.index)]}"]

  protocol = "tcp"
  security_group_id = "${aws_security_group.bastion_security_group.id}"
  type = "ingress"
}

output "bastion_security_group_id" {
  value = "${aws_security_group.bastion_security_group.id}"
}
