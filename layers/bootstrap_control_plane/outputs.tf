output "sjb_private_ip" {
  value = "${element(concat(module.sjb_bootstrap.eni_ips, list("")), 0)}"
}

output "sjb_private_key" {
  value     = "${module.sjb_key_pair.private_key_pem}"
  sensitive = true
}

output "sjb_ssh_key_pair_name" {
  value = "${module.sjb_key_pair.key_name}"
}

output "control_plane_public_cidrs" {
  value = "${module.public_subnets.subnet_cidr_blocks}"
}

output "control_plane_subnet_cidrs" {
  value = "${module.private_subnets.subnet_cidr_blocks}"
}

output "control_plane_subnet_availability_zones" {
  value = "${var.availability_zones}"
}

output "control_plane_subnet_gateways" {
  value = "${module.private_subnets.subnet_gateways}"
}

output "control_plane_subnet_ids" {
  value = "${module.private_subnets.subnet_ids}"
}

output "vms_security_group_id" {
  value = "${aws_security_group.vms_security_group.id}"
}

output "sjb_cidr_block" {
  value = "${local.sjb_cidr_block}"
}

output "sjb_eni_ids" {
  value = "${module.sjb_bootstrap.eni_ids}"
}

output "om_eni_id" {
  value = "${module.ops_manager.om_eni_id}"
}

output "om_eip_allocation_id" {
  value = "${module.ops_manager.om_eip_allocation_id}"
}

output "om_security_group_id" {
  value = "${module.ops_manager.security_group_id}"
}

output "om_ssh_public_key_pair_name" {
  value = "${module.om_key_pair.key_name}"
}

output "om_private_key_pem" {
  value = "${module.om_key_pair.private_key_pem}"
}

output "web_elb_id" {
  value = "${module.web_elb.my_elb_id}"
}

output "postgres_rds_address" {
  value = "${module.rds.rds_address}"
}

output "postgres_rds_port" {
  value = "${module.rds.rds_port}"
}

output "postgres_rds_username" {
  value = "${module.rds.rds_username}"
}

output "postgres_rds_password" {
  value     = "${module.rds.rds_password}"
  sensitive = true
}

output "mysql_rds_address" {
  value = "${aws_db_instance.rds.address}"
}

output "mysql_rds_port" {
  value = "${aws_db_instance.rds.port}"
}

output "mysql_rds_username" {
  value = "${aws_db_instance.rds.username}"
}

output "mysql_rds_password" {
  value     = "${random_string.rds_password.result}"
  sensitive = true
}

output "ops_manager_bucket_name" {
  value = "${module.ops_manager.bucket}"
}

output "mirror_bucket_name" {
  value = "${aws_s3_bucket.mirror_bucket.bucket}"
}

output "transfer_bucket_name" {
  value = "${aws_s3_bucket.transfer_bucket.bucket}"
}
