provider "aws" {
  version = "<=1.5.0"
}
variable "subnet_id" {
  description = "subnet to launch MJB in"
}

locals {
  vpc_id ="vpc-04268fe779b20e3ad"
  external_cidr_block = "72.83.230.85/32"
}

data "aws_vpc" "mjb_vpc" {
  id = "${local.vpc_id}"
}

data "aws_subnet" "mjb_subnet" {
  id = "${var.subnet_id}"
}

resource "aws_security_group" "mjb_security_group" {
  name_prefix = "mjb-sg"
  vpc_id = "${data.aws_subnet.mjb_subnet.vpc_id}"

  tags {
    Name="mjb-sg"
  }
}

resource "aws_security_group_rule" "ingress_ssh" {
  from_port = 22
  protocol = "tcp"
  security_group_id = "${aws_security_group.mjb_security_group.id}"
  to_port = 22
  type = "ingress"
  cidr_blocks = ["${data.aws_subnet.mjb_subnet.cidr_block}",
                "${local.external_cidr_block}"]
}

resource "aws_security_group_rule" "egress_everywhere" {
    type              = "egress"
    to_port           = 0
    protocol          = "-1"
    from_port         = 0
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.mjb_security_group.id}"
  }

locals {
  //hack to fix the path for windows, theoretically this will be fixed in v 0.12 to use same convention on all OS
  module_path = "${replace(path.module, "\\", "/")}"
  users_file      = "${local.module_path}/users.yml"
  cas_file      = "${local.module_path}/ca_update.yml"
}

module "find_mjb_ami" {
  source = "../../../../modules/master-jump-box/lookup-ami"
}

module "mjb_instance" {
  source = "../../../../modules/master-jump-box/launch"
  ami_id = "${module.find_mjb_ami.id}"
  instance_type = "m4.xlarge"
  subnet_id = "${data.aws_subnet.mjb_subnet.id}"
  instance_profile = "DIRECTOR"
  security_group_id = "${aws_security_group.mjb_security_group.id}"
  users_yml = "${local.users_file}"
  trusted_cas_yml = "${local.cas_file}"
}