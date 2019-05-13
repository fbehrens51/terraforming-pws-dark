resource "aws_elb" "elb" {
  name = "${var.name}"
  cross_zone_load_balancing = true
  internal = "${var.internetless}"
  subnets = ["${var.public_subnet_ids}"]

  security_groups = ["${var.elb_sg_id}"]
  idle_timeout = 600

  listener {
    instance_port = 443
    instance_protocol = "TCP"
    lb_port = 443
    lb_protocol = "TCP"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 2
    target = "TCP:443"
    interval = 5
  }

  tags = "${var.elb_tag}"
}

variable "internetless" {}

variable "public_subnet_ids" {
  type = "list"
}

variable "elb_sg_id" {}

variable "elb_tag" {
  type = "map"
}

variable "name" {}

output "elb_id" {
  value = "${aws_elb.elb.id}"
}
