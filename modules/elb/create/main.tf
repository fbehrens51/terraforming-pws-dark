locals {
  formatted_env_name = "${replace(var.env_name," ","-")}"
}

module "pas_elb" {
  source            = "elb"
  name              = "${local.formatted_env_name}-pas-elb"
  elb_tag           = "${merge(var.tags, map("Name", "${var.env_name} pas elb"))}"
  elb_sg_id         = "${aws_security_group.web_elb_sg.id}"
  internetless      = "${var.internetless}"
  public_subnet_ids = "${var.public_subnet_ids}"
}

module "om_elb" {
  source            = "elb"
  name              = "${local.formatted_env_name}-om-elb"
  elb_tag           = "${merge(var.tags, map("Name", "${var.env_name} om elb"))}"
  elb_sg_id         = "${aws_security_group.web_elb_sg.id}"
  internetless      = "${var.internetless}"
  public_subnet_ids = "${var.public_subnet_ids}"
}
