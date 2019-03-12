resource "aws_route53_record" "wildcard_sys_dns" {
  count   = "${var.use_route53}"
  zone_id = "${var.zone_id}"
  name    = "*.sys.${var.env_name}.${var.dns_suffix}"
  type    = "CNAME"
  ttl     = 300

  records = ["${aws_lb.web.dns_name}"]
}

resource "aws_route53_record" "wildcard_apps_dns" {
  count   = "${var.use_route53}"
  zone_id = "${var.zone_id}"
  name    = "*.apps.${var.env_name}.${var.dns_suffix}"
  type    = "CNAME"
  ttl     = 300

  records = ["${aws_lb.web.dns_name}"]
}

resource "aws_route53_record" "ssh" {
  count   = "${var.use_route53 && var.use_ssh_routes? 1 : 0}"
  zone_id = "${var.zone_id}"
  name    = "ssh.sys.${var.env_name}.${var.dns_suffix}"
  type    = "CNAME"
  ttl     = 300

  records = ["${aws_lb.ssh.dns_name}"]
}

resource "aws_route53_record" "tcp" {
  count   = "${var.use_route53 && var.use_tcp_routes ? 1 : 0}"
  zone_id = "${var.zone_id}"
  name    = "tcp.${var.env_name}.${var.dns_suffix}"
  type    = "CNAME"
  ttl     = 300

  records = ["${aws_lb.tcp.dns_name}"]
}
