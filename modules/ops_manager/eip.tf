resource "aws_eip" "ops_manager_attached" {
  instance = "${aws_instance.ops_manager.id}"
  count    = "${var.om_eip ? var.vm_count : 0}"
  vpc      = true

  tags = "${merge(var.tags, map("Name", "${var.env_name}-om-eip"))}"
}

resource "aws_eip" "ops_manager_unattached" {
  count = "${var.vm_count > 0 ? 0 : var.om_eip}"
  vpc   = true

  tags = "${merge(var.tags, map("Name", "${var.env_name}-om-eip"))}"
}

resource "aws_eip" "optional_ops_manager" {
  instance = "${aws_instance.optional_ops_manager.id}"
  count    = "${var.om_eip ? var.optional_count: 0}"
  vpc      = true

  tags = "${merge(var.tags, map("Name", "${var.env_name}-optional-om-eip"))}"
}
