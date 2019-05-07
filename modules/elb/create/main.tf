resource "aws_security_group" "web_elb_sg" {
  name_prefix = "web_lb_security_group"
  description = "Load Balancer Security Group"
  vpc_id = "${var.vpc_id}"

  tags = "${merge(var.tags, map("Name", "${var.env_name}-web-elb-sg"))}"
}

resource "aws_security_group_rule" "web_ingress" {
  from_port = 443
  to_port = 443
  protocol = "TCP"
  type = "ingress"
  security_group_id = "${aws_security_group.web_elb_sg.id}"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "web_egress" {
  from_port = 0
  to_port = 0
  protocol = "-1"
  type = "egress"
  security_group_id = "${aws_security_group.web_elb_sg.id}"
  cidr_blocks = ["${var.egress_cidrs}"]
}

resource "aws_elb" "pas_elb" {
  name_prefix = "pas-lb"
  cross_zone_load_balancing = true
  internal = "${var.internetless}"
  subnets = [
    "${var.public_subnet_ids}"]

  security_groups = ["${aws_security_group.web_elb_sg.id}"]
  idle_timeout = 600

  listener {
    instance_port = 443
    instance_protocol = "TCP"
    lb_port = 443
    lb_protocol = "TCP"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 2
    target              = "TCP:443"
    interval            = 5
  }

  tags = "${merge(var.tags, map("Name", "${var.env_name}-pas_elb"))}"
}

variable "vpc_id" {}

variable "tags" {
  type = "map"
}

variable "env_name" {}

variable "internetless" {}

variable "public_subnet_ids" {
  type = "list"
}

variable "egress_cidrs" {
  type = "list"
}
