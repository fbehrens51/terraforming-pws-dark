
resource aws_lb ldap {
  name               = "ldap-lb"
  internal           = false
  load_balancer_type = "network"
  subnets            = aws_subnet.public.*.id
}

resource aws_lb_listener ldap {
  load_balancer_arn = aws_lb.ldap.arn
  port              = local.external_ldap_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ldap.arn
  }
}

resource aws_lb_listener ldaps {
  load_balancer_arn = aws_lb.ldap.arn
  port              = local.external_ldaps_port
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.ldap.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ldap.arn
  }
}

resource aws_lb_target_group ldap {
  name        = "ldap"
  port        = local.ldap_port
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id

  depends_on = [aws_lb.ldap]

  stickiness {
    enabled = false
    type    = "lb_cookie"
  }
}
