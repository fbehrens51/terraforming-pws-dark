resource "aws_elb" "elb" {
  count = 1

  name                      = var.name
  cross_zone_load_balancing = true
  internal                  = var.internetless
  subnets                   = var.public_subnet_ids

  security_groups = [var.elb_sg_id]
  idle_timeout    = 600

  listener {
    instance_port     = var.instance_port
    instance_protocol = "TCP"
    lb_port           = var.port
    lb_protocol       = "TCP"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 2
    target              = var.health_check
    interval            = 5
  }

  tags = var.elb_tag
}

resource "aws_proxy_protocol_policy" "proxy_policy" {
  count          = var.proxy_pass == true ? 1 : 0
  load_balancer  = aws_elb.elb[count.index].name
  instance_ports = [var.instance_port]
}

variable "instance_port" {
}

variable "port" {
  type = string
}

variable "internetless" {
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "elb_sg_id" {
}

variable "elb_tag" {
  type = map(string)
}

variable "name" {
}

variable "health_check" {
}

variable "proxy_pass" {
}

output "elb_id" {
  value = aws_elb.elb[0].id
}

output "dns_name" {
  value = aws_elb.elb[0].dns_name
}

