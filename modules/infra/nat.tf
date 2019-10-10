module "nat" {
  source                 = "../nat"
  private_route_table_id = "${var.private_route_table_id}"
  tags                   = "${var.tags}"
  public_subnet_id       = "${element(aws_subnet.public_subnets.*.id, 0)}"
  bastion_private_ip     = "${var.bastion_private_ip}/32"
  internetless           = "${var.internetless}"
  instance_type          = "${var.nat_instance_type}"
  user_data              = "${var.user_data}"
  ssh_banner             = "${var.ssh_banner}"
}
