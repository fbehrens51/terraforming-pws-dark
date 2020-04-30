
variable "env_name" {}
variable "service_name" {}
variable "vpc_id" {}
variable "health_check_path" {}
variable "server_cert_pem" {}
variable "server_key_pem" {}
variable "alb_listener_arn" {}
variable "domain" {}
variable "priority" {
  type = number
}
variable "ips" {
  type = list(string)
}
variable "port" {
  type = number
}

resource "aws_lb_target_group" "service" {
  name        = "${replace(var.env_name, " ", "-")}-${var.service_name}"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    protocol = "HTTPS"
    path     = var.health_check_path
    matcher  = "200"
  }
}

resource "aws_iam_server_certificate" "service" {
  name             = "${replace(var.env_name, " ", "-")}-${var.service_name}"
  private_key      = var.server_key_pem
  certificate_body = var.server_cert_pem
}

resource "aws_lb_listener_certificate" "service" {
  listener_arn    = var.alb_listener_arn
  certificate_arn = aws_iam_server_certificate.service.arn
}

resource "aws_lb_listener_rule" "service" {
  listener_arn = var.alb_listener_arn
  priority     = var.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service.arn
  }

  condition {
    host_header {
      values = [var.domain]
    }
  }
}

resource "aws_alb_target_group_attachment" "service" {
  count            = length(var.ips)
  target_group_arn = aws_lb_target_group.service.arn
  target_id        = var.ips[count.index]
  port             = var.port
}

output "target_group_id" {
  value = aws_lb_target_group.service.id
}
