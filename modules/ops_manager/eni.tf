resource "aws_network_interface" "ops_manager_attached" {
  subnet_id = "${var.subnet_id}"
  count     = "${var.om_eni ? var.vm_count : 0}"

  attachment {
    device_index = 1
    instance     = "${aws_instance.ops_manager.id}"
  }

  tags = "${merge(var.tags, map("Name", "${var.env_name}-om-eni"))}"
}

resource "aws_network_interface" "ops_manager_unattached" {
  subnet_id = "${var.subnet_id}"
  count     = "${var.vm_count > 0 ? 0 : var.om_eni}"

  tags = "${merge(var.tags, map("Name", "${var.env_name}-om-eni"))}"
}

resource "aws_network_interface" "optional_ops_manager" {
  subnet_id = "${var.subnet_id}"
  count     = "${var.om_eni ? var.optional_count: 0}"

  attachment {
    device_index = 0
    instance     = "${aws_instance.optional_ops_manager.id}"
  }

  tags = "${merge(var.tags, map("Name", "${var.env_name}-optional-om-eni"))}"
}
