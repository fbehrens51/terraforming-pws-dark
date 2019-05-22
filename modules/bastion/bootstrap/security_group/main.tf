variable "vpc_id" {}

variable "ingress_rules" {
  type = "list"
}

variable "egress_rules" {
  type = "list"
}

resource "aws_security_group" "bastion_security_group" {
  name_prefix = "bastion_sg-"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name = "bastion-sg"
  }
}

resource "aws_security_group_rule" "egress_rules" {
  count = "${length(var.egress_rules)}"

  from_port = "${lookup(var.egress_rules[count.index], "port")}"
  to_port   = "${lookup(var.egress_rules[count.index], "port")}"

  cidr_blocks = "${split(",", lookup(var.egress_rules[count.index], "cidr_blocks"))}"

  protocol          = "${lookup(var.egress_rules[count.index], "protocol")}"
  security_group_id = "${aws_security_group.bastion_security_group.id}"
  type              = "egress"
}

resource "aws_security_group_rule" "ingress_rules" {
  count = "${length(var.ingress_rules)}"

  from_port = "${lookup(var.ingress_rules[count.index], "port")}"
  to_port   = "${lookup(var.ingress_rules[count.index], "port")}"

  cidr_blocks = "${split(",", lookup(var.ingress_rules[count.index], "cidr_blocks"))}"

  protocol          = "${lookup(var.ingress_rules[count.index], "protocol")}"
  security_group_id = "${aws_security_group.bastion_security_group.id}"
  type              = "ingress"
}

output "bastion_security_group_id" {
  value = "${aws_security_group.bastion_security_group.id}"
}
