//TODO: terraform thinks the user_data is changing when running on different machines.  Need to research
variable "ami_id" {
  description = "ami ID to use to launch instance"
}

variable "instance_type" {
  default = "t2.small"
}

variable "user_data" {
  description = "user data"
}

variable "subnet_id" {
}

variable "security_group_ids" {
  type = "list"
  default = []
}


locals {
  createdTimestamp="${timestamp()}"
}

resource "aws_instance" "bastion" {
  subnet_id = "${var.subnet_id}"

  ami = "${var.ami_id}"
  instance_type = "${var.instance_type}"
  user_data = "${var.user_data}"
  vpc_security_group_ids = ["${var.security_group_ids}"]

  tags {
    Name="BASTION ${local.createdTimestamp}"
    CreatedTimestamp="${local.createdTimestamp}"
    SourceAmiId="${var.ami_id}"
  }

  lifecycle {
    ignore_changes = ["tags.CreatedTimestamp", "tags.Name", "tags.%"]
  }
}

output "bastion_instance_id" {
  value = "${aws_instance.bastion.id}"
}
