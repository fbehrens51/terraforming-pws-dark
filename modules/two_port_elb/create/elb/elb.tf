resource "aws_elb" "elb" {
  name                      = "${var.name}"
  cross_zone_load_balancing = true
  internal                  = "${var.internetless}"
  subnets                   = ["${var.public_subnet_ids}"]

  security_groups = ["${var.elb_sg_id}"]
  idle_timeout    = 600

  listener {
    instance_port     = "${var.port}"
    instance_protocol = "TCP"
    lb_port           = "${var.port}"
    lb_protocol       = "TCP"
  }

  listener {
    instance_port     = "${var.additional_port}"
    instance_protocol = "TCP"
    lb_port           = "${var.additional_port}"
    lb_protocol       = "TCP"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 2
    target              = "${var.health_check}"
    interval            = 5
  }

  tags = "${var.elb_tag}"
}

variable "port" {}
variable "additional_port" {}

variable "internetless" {}

variable "public_subnet_ids" {
  type = "list"
}

variable "elb_sg_id" {}

variable "elb_tag" {
  type = "map"
}

variable "name" {}

variable "health_check" {}

output "elb_id" {
  value = "${element(concat(aws_elb.elb.*.id, list("")), 0)}"
}

output "dns_name" {
  value = "${element(concat(aws_elb.elb.*.dns_name, list("")), 0)}"
}
