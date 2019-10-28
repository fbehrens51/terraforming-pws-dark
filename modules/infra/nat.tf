module "nat" {
  source                 = "../nat"
  private_route_table_id = "${var.private_route_table_id}"
  tags                   = "${var.tags}"
  public_subnet_id       = "${element(aws_subnet.public_subnets.*.id, 0)}"
  bastion_private_ip     = "${var.bastion_private_ip}/32"
  internetless           = "${var.internetless}"
  instance_type          = "${var.nat_instance_type}"
  user_data              = "${var.user_data}"

  root_domain           = "${var.root_domain}"
  splunk_syslog_ca_cert = "${var.splunk_syslog_ca_cert}"

  public_bucket_name = "${var.public_bucket_name}"
  public_bucket_url  = "${var.public_bucket_url}"
}
