variable "ami_id" {
  description = "ami ID to use to launch instance"
}
variable "enable_public_ip" {
  default = false
}

variable "instance_type" {
  default = "t2.small"
}

variable "subnet_id" {}


variable "user_data" {
  description = "user data"
}

variable "ssh_cidrs"{
  type = "list"
}

data "aws_subnet" "targeted_subnet" {
  id = "${var.subnet_id}"
}

resource "aws_security_group" "bastion_security_group" {
  name_prefix = "bastion_sg-"
  vpc_id = "${data.aws_subnet.targeted_subnet.vpc_id}"
  tags {
    Name="bastion-sg"
  }
}

locals {
  createdTimestamp="${timestamp()}"
}

resource "aws_security_group_rule" "ssh_ingress" {
  from_port = 22
  protocol = "tcp"
  security_group_id = "${aws_security_group.bastion_security_group.id}"
  to_port = 22
  type = "ingress"
  cidr_blocks = ["${var.ssh_cidrs}"]
  depends_on = ["aws_security_group.bastion_security_group"]
}

resource "aws_security_group_rule" "ssh_egress" {
  from_port = 22
  protocol = "tcp"
  security_group_id = "${aws_security_group.bastion_security_group.id}"
  to_port = 22
  type = "egress"
  cidr_blocks = ["0.0.0.0/0"]
  depends_on = ["aws_security_group.bastion_security_group"]
}

resource "aws_instance" "bastion" {
  ami = "${var.ami_id}"
  instance_type = "${var.instance_type}"
  user_data = "${var.user_data}"
  associate_public_ip_address = "${var.enable_public_ip}"
  subnet_id = "${data.aws_subnet.targeted_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.bastion_security_group.id}"]

  tags {
    Name="BASTION ${local.createdTimestamp}"
    CreatedTimestamp="${local.createdTimestamp}"
    SourceAmiId="${var.ami_id}"
  }

  lifecycle {
    ignore_changes = ["tags.CreatedTimestamp", "tags.Name", "tags.%"]
  }
  depends_on = ["aws_security_group.bastion_security_group"]
}
