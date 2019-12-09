module "nat" {
  source                  = "../nat"
  ami_id                  = "${var.nat_ami_id}"
  private_route_table_ids = "${var.private_route_table_ids}"
  vpc_id                  = "${var.vpc_id}"
  tags                    = "${var.tags}"
  public_subnet_ids       = "${aws_subnet.public_subnets.*.id}"
  bastion_private_ip      = "${var.bastion_private_ip}/32"
  internetless            = "${var.internetless}"
  instance_type           = "${var.nat_instance_type}"
  user_data               = "${var.user_data}"

  root_domain           = "${var.root_domain}"
  splunk_syslog_ca_cert = "${var.splunk_syslog_ca_cert}"

  public_bucket_name = "${var.public_bucket_name}"
  public_bucket_url  = "${var.public_bucket_url}"
}
