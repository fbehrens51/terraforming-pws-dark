resource "aws_eip" "ops_manager_unattached" {
  count = var.om_eip ? 1 : 0
  vpc   = true
  network_interface = aws_network_interface.ops_manager_unattached[0].id
  tags = merge(
    var.tags,
    {
      "Name" = "${var.env_name}-om-eip"
    },
  )
}
