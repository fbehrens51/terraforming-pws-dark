resource "aws_eip" "ops_manager_unattached" {
  count = var.om_eip ? 1 : 0
  vpc   = true

  tags = merge(
    var.tags,
    {
      "Name" = "${var.env_name}-om-eip"
    },
  )
}

