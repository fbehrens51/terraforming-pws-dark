module "nat" {
  source                 = "../nat"
  private_route_table_id = "${var.private_route_table_id}"
  tags                   = "${var.tags}"
  public_subnet_id       = "${element(aws_subnet.public_subnets.*.id, 0)}"
  internetless           = "${var.internetless}"
}
