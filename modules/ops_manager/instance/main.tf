variable "ami" {}

variable "instance_type" {}
variable "key_pair_name" {}

variable "instance_profile" {}

variable "tags" {
  type = "map"
}

variable "env_name" {}

variable "eni_id" {}

resource "aws_instance" "ops_manager" {
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  key_name      = "${var.key_pair_name}"

  network_interface {
    device_index         = 0
    network_interface_id = "${var.eni_id}"
  }

  iam_instance_profile = "${var.instance_profile}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 150
  }

  tags = "${merge(var.tags, map("Name", "${var.env_name}-ops-manager"))}"
}

output "instance_id" {
  value = "${aws_instance.ops_manager.id}"
}

output "private_ip" {
  value = "${aws_instance.ops_manager.private_ip}"
}
