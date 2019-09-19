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

variable "eni_ids" {
  type = "list"
}

variable "key_pair_name" {
  default = ""
}

variable "iam_instance_profile" {
  default = ""
}

variable "tags" {
  type = "map"
}

//allows calling module to set a fixed count since count cannot use a value calculated from something that may not exist yet (e.g. eni_ids)
variable "instance_count" {
  default = 1
}

locals {
  created_timestamp = "${timestamp()}"

  computed_instance_tags = {
    CreatedTimestamp = "${local.created_timestamp}"
    SourceAmiId      = "${var.ami_id}"
  }
}

variable "root_block_device" {
  type    = "map"
  default = {}
}

resource "aws_instance" "instance" {
  count = "${var.instance_count}"

  network_interface {
    device_index         = 0
    network_interface_id = "${var.eni_ids[count.index]}"
  }

  ami                  = "${var.ami_id}"
  instance_type        = "${var.instance_type}"
  user_data            = "${var.user_data}"
  key_name             = "${var.key_pair_name}"
  iam_instance_profile = "${var.iam_instance_profile}"

  tags              = "${merge(var.tags, local.computed_instance_tags)}"
  root_block_device = ["${var.root_block_device}"]

  lifecycle {
    // We don't want terraform to remove tags applied later by customer processes
    ignore_changes = ["tags", "user_data"]
  }
}

output "instance_ids" {
  value = "${aws_instance.instance.*.id}"
}

output "private_ips" {
  value = "${aws_instance.instance.*.private_ip}"
}
