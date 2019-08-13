resource "aws_network_interface" "ops_manager_unattached" {
  count = 1

  subnet_id       = "${var.subnet_id}"
  tags            = "${merge(var.tags, map("Name", "${var.env_name}-om-eni"))}"
  security_groups = ["${aws_security_group.ops_manager_security_group.id}"]
}
