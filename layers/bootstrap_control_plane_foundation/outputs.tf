output "om_eni_id" {
  value = module.ops_manager.om_eni_id
}

output "om_eip_allocation" {
  value = module.ops_manager.om_eip_allocation
}

output "om_security_group_id" {
  value = module.ops_manager.security_group_id
}

output "credhub_tg_ids" {
  value = module.concourse_nlb.credhub_tg_ids
}

output "uaa_elb_id" {
  value = module.uaa_elb.my_elb_id
}

output "credhub_elb_id" {
  value = module.credhub_elb.my_elb_id
}

output "web_tg_ids" {
  value = module.concourse_nlb.web_tg_ids
}

output "postgres_rds_address" {
  value = module.postgres.rds_address
}

output "postgres_rds_port" {
  value = module.postgres.rds_port
}

output "postgres_rds_username" {
  value = module.postgres.rds_username
}

output "postgres_rds_password" {
  value     = module.postgres.rds_password
  sensitive = true
}

output "mysql_rds_address" {
  value = module.mysql.rds_address
}

output "mysql_rds_port" {
  value = module.mysql.rds_port
}

output "mysql_rds_username" {
  value = module.mysql.rds_username
}

output "mysql_rds_password" {
  value     = module.mysql.rds_password
  sensitive = true
}

output "mysql_rds_subnet_group_name" {
  value = module.rds_subnet_group.subnet_group_name
}

output "ops_manager_bucket_name" {
  value = module.ops_manager.bucket
}

output "ops_manager_bucket_arn" {
  value = module.ops_manager.bucket_arn
}

output "director_blobstore_bucket" {
  value = module.ops_manager.director_blobstore_bucket
}

output "mirror_bucket_name" {
  value = aws_s3_bucket.mirror_bucket.bucket
}

output "transfer_bucket_name" {
  value = aws_s3_bucket.transfer_bucket.bucket
}

output "import_bucket_name" {
  value = aws_s3_bucket.import_bucket.bucket
}

output "ops_manager_ip" {
  value = module.ops_manager.ip
}

output "uaa_elb_dns" {
  value = module.uaa_elb.dns_name
}

output "credhub_elb_dns" {
  value = module.credhub_elb.dns_name
}

output "plane_elb_dns" {
  value = module.concourse_nlb.concourse_nlb_dns_name
}

output "concourse_lb_security_group_id" {
  value = [
    module.concourse_nlb.concourse_nlb_security_group_id,
    data.terraform_remote_state.bootstrap_control_plane.outputs.vms_security_group_id
  ]
}

output "terraform_region" {
  value = var.terraform_region
}

output "om_private_key_pem" {
  value     = module.om_key_pair.private_key_pem
  sensitive = true
}