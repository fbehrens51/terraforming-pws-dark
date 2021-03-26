
resource "aws_acm_certificate" "ldap" {
  private_key       = tls_private_key.ldap.private_key_pem
  certificate_body  = tls_locally_signed_cert.ldap.cert_pem
  certificate_chain = tls_self_signed_cert.root.cert_pem
}

resource aws_lb ldap {
  name               = "ldap-lb"
  internal           = false
  load_balancer_type = "network"
  subnets            = aws_subnet.public.*.id
}

resource aws_lb_listener ldap {
  load_balancer_arn = aws_lb.ldap.arn
  port              = local.ldap_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ldap.arn
  }
}

resource aws_lb_listener ldaps {
  load_balancer_arn = aws_lb.ldap.arn
  port              = local.ldaps_port
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
