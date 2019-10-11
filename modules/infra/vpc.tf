data "aws_vpc" "vpc" {
  id = "${var.vpc_id}"
}

resource "aws_security_group" "vms_security_group" {
  count = 1

  name        = "vms_security_group"
  description = "VMs Security Group"
  vpc_id      = "${data.aws_vpc.vpc.id}"

  ingress {
    cidr_blocks = ["${var.bastion_private_ip}/32"]
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
  }

  ingress {
    cidr_blocks = ["${data.aws_vpc.vpc.cidr_block}"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  tags = "${merge(var.tags, map("Name", "${var.env_name}-vms-security-group"))}"
}
