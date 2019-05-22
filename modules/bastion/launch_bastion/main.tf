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

variable "bastion_eni_id" {}

variable "key_pair_name" {
  default = ""
}

locals {
  createdTimestamp = "${timestamp()}"
}

resource "aws_instance" "bastion_instance" {
  network_interface {
    device_index         = 0
    network_interface_id = "${var.bastion_eni_id}"
  }

  ami           = "${var.ami_id}"
  instance_type = "${var.instance_type}"
  user_data     = "${var.user_data}"
  key_name      = "${var.key_pair_name}"

  tags {
    Name             = "BASTION ${local.createdTimestamp}"
    CreatedTimestamp = "${local.createdTimestamp}"
    SourceAmiId      = "${var.ami_id}"
  }

  lifecycle {
    // We don't want terraform to remove tags applied later by customer processes
    ignore_changes = ["tags"]
  }
}

output "bastion_instance_id" {
  value = "${aws_instance.bastion_instance.id}"
}
