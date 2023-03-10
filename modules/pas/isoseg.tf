resource "aws_security_group" "isoseg_lb_security_group" {
  count = var.create_isoseg_resources

  name        = "isoseg_lb_security_group"
  description = "Isoseg Load Balancer Security Group"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow http/80 from everywhere"
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
  }

  ingress {
    description = "Allow https/443 from everywhere"
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
  }

  ingress {
    description = "Allow tcp/8443 from everywhere"
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 4443
    to_port     = 4443
  }

  egress {
    description = "Allow all protocols/ports to everywhere"
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.env_name}-isoseg-lb-security-group"
      Description = "pas/isoseg"
    },
  )
}

resource "aws_lb" "isoseg" {
  count = var.create_isoseg_resources

  name                             = "${var.env_name}-isoseg-lb"
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = true
  internal                         = false
  subnets                          = var.public_subnet_ids

  tags = var.tags
}

resource "aws_lb_listener" "isoseg_80" {
  load_balancer_arn = aws_lb.isoseg[0].arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.isoseg_80[0].arn
  }

  count = var.create_isoseg_resources
}

resource "aws_lb_listener" "isoseg_443" {
  load_balancer_arn = aws_lb.isoseg[0].arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.isoseg_443[0].arn
  }

  count = var.create_isoseg_resources
}

resource "aws_lb_listener" "isoseg_4443" {
  load_balancer_arn = aws_lb.isoseg[0].arn
  port              = 4443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.isoseg_4443[0].arn
  }

  count = var.create_isoseg_resources
}

resource "aws_lb_target_group" "isoseg_80" {
  name     = "${var.env_name}-iso-tg-80"
  port     = 80
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    protocol = "TCP"
  }

  count = var.create_isoseg_resources
}

resource "aws_lb_target_group" "isoseg_443" {
  name     = "${var.env_name}-iso-tg-443"
  port     = 443
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    protocol = "TCP"
  }

  count = var.create_isoseg_resources
}

resource "aws_lb_target_group" "isoseg_4443" {
  name     = "${var.env_name}-iso-tg-4443"
  port     = 4443
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    protocol = "TCP"
  }

  count = var.create_isoseg_resources
}

resource "aws_route53_record" "wildcard_iso_dns" {
  zone_id = var.zone_id
  name    = "*.iso.${var.env_name}.${var.dns_suffix}"
  type    = "CNAME"
  ttl     = 300
  count   = var.create_isoseg_resources

  records = [aws_lb.isoseg[0].dns_name]
}

