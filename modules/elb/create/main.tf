locals {
  formatted_env_name = "${replace(var.env_name," ","-")}"
}

module "my_elb" {
  source            = "../create/elb"
  name              = "${local.formatted_env_name}-${var.short_name}-elb"
  elb_tag           = "${merge(var.tags, map("Name", "${var.env_name} ${var.short_name} elb"))}"
  elb_sg_id         = "${aws_security_group.my_elb_sg.id}"
  internetless      = "${var.internetless}"
  public_subnet_ids = "${var.public_subnet_ids}"
  port              = "${var.port}"
}
