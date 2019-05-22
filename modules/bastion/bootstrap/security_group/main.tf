variable "vpc_id" {}

variable "ingress_rules" {
  type = "map"
}

resource "aws_security_group" "bastion_security_group" {
  name_prefix = "bastion_sg-"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name = "bastion-sg"
  }
}

resource "aws_security_group_rule" "ssh_egress" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.bastion_security_group.id}"
  to_port           = 22
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  depends_on        = ["aws_security_group.bastion_security_group"]
}

resource "aws_security_group_rule" "ingress_rules" {
  count = "${length (var.ingress_rules)}"

  from_port = "${element(keys(var.ingress_rules), count.index)}"
  to_port   = "${element(keys(var.ingress_rules), count.index)}"

  cidr_blocks = ["${var.ingress_rules[element(keys(var.ingress_rules), count.index)]}"]

  protocol          = "tcp"
  security_group_id = "${aws_security_group.bastion_security_group.id}"
  type              = "ingress"
}

output "bastion_security_group_id" {
  value = "${aws_security_group.bastion_security_group.id}"
}
