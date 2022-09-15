locals {
  proxy_instance_ports = [for i, v in var.listener_to_instance_ports : v.instance_port if v.enable_proxy_policy]
}

resource "aws_elb" "elb" {
  count = 1

  name                      = var.name
  cross_zone_load_balancing = true
  internal                  = var.internetless
  subnets                   = var.public_subnet_ids

  security_groups = [var.elb_sg_id]
  idle_timeout    = var.idle_timeout

  dynamic "listener" {
    for_each = var.listener_to_instance_ports
    content {
      instance_port     = listener.value["instance_port"]
      instance_protocol = "TCP"
      lb_port           = listener.value["port"]
      lb_protocol       = "TCP"
    }
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
  instance_ports = local.proxy_instance_ports
}


variable "idle_timeout" {
  type        = number
  default     = 600
  description = "idle timeout in seconds for the elb"
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

variable "listener_to_instance_ports" {
  type = list(object({
    port                = string
    instance_port       = string
    enable_proxy_policy = bool
  }))
}

output "elb_id" {
  value = aws_elb.elb[0].id
}

output "dns_name" {
  value = aws_elb.elb[0].dns_name
}

