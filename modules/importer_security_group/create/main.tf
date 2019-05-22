variable "vpc_id" {
  description = "VPC to create Security Group in"
}

variable "external_cidr_blocks" {
  description = "cidr blocks to allow ssh access from (where is terraform being run if not in the VPC)"
  type        = "list"
  default     = []
}

locals {
  enable_public_ip = "${length(var.external_cidr_blocks) <1  ? false : true}"
  importer_sg_name = "vm_importer_security_group"
}

resource "aws_security_group" "vm_importer_security_group" {
  vpc_id      = "${var.vpc_id}"
  name_prefix = "${local.importer_sg_name}"
  description = "Ops Manager Exporter Security Group"

  //added to allow access to S3
  //We could instead set up the VPC S3 endpoint and restrict to that only...
  egress {
    cidr_blocks = [
      "0.0.0.0/0",
    ]

    protocol  = "-1"
    from_port = 0
    to_port   = 0
  }

  tags {
    Name = "${local.importer_sg_name}"
  }
}

resource "aws_security_group_rule" "ingress_local_ssh" {
  count             = "${local.enable_public_ip == false ? 1 : 0}"
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.vm_importer_security_group.id}"
  to_port           = 22
  type              = "ingress"

  cidr_blocks = [
    "0.0.0.0/0",
  ]
}

resource "aws_security_group_rule" "ingress_external_ssh" {
  count             = "${local.enable_public_ip == true ? 1 : 0}"
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.vm_importer_security_group.id}"
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = "${var.external_cidr_blocks}"
}

output "id" {
  value = "${aws_security_group.vm_importer_security_group.id}"
}
