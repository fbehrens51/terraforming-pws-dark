module "pas_elb" {
  source = "elb"
  name = "${var.env_name}-pas-elb"
  elb_tag = "${merge(var.tags, map("Name", "${var.env_name} pas elb"))}"
  elb_sg_id = "${aws_security_group.web_elb_sg.id}"
  internetless = "${var.internetless}"
  public_subnet_ids = "${var.public_subnet_ids}"
}

module "om_elb" {
  source = "elb"
  name = "${var.env_name}-om-elb"
  elb_tag = "${merge(var.tags, map("Name", "${var.env_name} om elb"))}"
  elb_sg_id = "${aws_security_group.web_elb_sg.id}"
  internetless = "${var.internetless}"
  public_subnet_ids = "${var.public_subnet_ids}"
}

resource "aws_elb_attachment" "om_elb_attachment" {
  elb = "${module.om_elb.elb_id}"
  instance = "${var.ops_manager_instance_id}"
}

variable "vpc_id" {}

variable "tags" {
  type = "map"
}

variable "env_name" {}

variable "internetless" {}

variable "public_subnet_ids" {
  type = "list"
}

variable "egress_cidrs" {
  type = "list"
}

variable "ops_manager_instance_id" {}
