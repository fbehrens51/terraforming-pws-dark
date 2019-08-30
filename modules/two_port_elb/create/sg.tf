resource "aws_security_group" "my_elb_sg" {
  name   = "${var.env_name} ${var.short_name} security group"
  vpc_id = "${var.vpc_id}"

  tags = "${merge(var.tags, map("Name", "${var.env_name} ${var.short_name} security group"))}"
}

resource "aws_security_group_rule" "port_ingress_rule" {
  from_port         = "${var.port}"
  to_port           = "${var.port}"
  protocol          = "TCP"
  type              = "ingress"
  security_group_id = "${aws_security_group.my_elb_sg.id}"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "additional_port_ingress_rule" {
  from_port         = "${var.additional_port}"
  to_port           = "${var.additional_port}"
  protocol          = "TCP"
  type              = "ingress"
  security_group_id = "${aws_security_group.my_elb_sg.id}"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_rule" {
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  type              = "egress"
  security_group_id = "${aws_security_group.my_elb_sg.id}"
  cidr_blocks       = ["${var.egress_cidrs}"]
}
