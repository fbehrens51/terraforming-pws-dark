

locals {
  pas_subnet_cidr = "${var.pas_subnet_cidrs[0]}"
}

data "template_file" "tile_vars" {
  template = "${file("${path.module}/tile_vars.tpl")}"
  vars = {
    rds_address = "${var.rds_address}"
    rds_password = "${var.rds_password}"
    rds_port = "${var.rds_port}"
    rds_username = "${var.rds_username}"

    redis_host = "${var.redis_host}"
    redis_password = "${var.redis_password}"

    pas_bucket_iam_instance_profile_name = "${var.pas_bucket_iam_instance_profile_name}"
    pas_buildpacks_bucket = "${var.pas_buildpacks_bucket}"
    pas_droplets_bucket = "${var.pas_droplets_bucket}"
    pas_packages_bucket = "${var.pas_packages_bucket}"
    pas_resources_bucket = "${var.pas_resources_bucket}"

    pas_subnet_availability_zone = "${var.pas_subnet_availability_zones[0]}"
    pas_subnet_cidr = "${local.pas_subnet_cidr}"
    pas_subnet_gateway = "${var.pas_subnet_gateways[0]}"
    pas_subnet_subnet_id = "${var.pas_subnet_ids[0]}"
    pas_subnet_reserved_ips = "${cidrhost(local.pas_subnet_cidr, 1)}-${cidrhost(local.pas_subnet_cidr, 4)}"

    vms_security_group_id = "${var.vms_security_group_id}"

    region = "${var.region}"

    ssh_key_name = "${var.ops_manager_ssh_public_key_name}"
    ssh_private_key = "${var.ops_manager_ssh_private_key}"
  }
}

data "template_file" "create_db" {
  template = "${file("${path.module}/create_db.tpl")}"
  vars = {
    rds_address = "${var.rds_address}"
    rds_password = "${var.rds_password}"
    rds_username = "${var.rds_username}"
  }
}

data "template_file" "drop_db" {
  template = "${file("${path.module}/drop_db.tpl")}"
  vars = {
    rds_address = "${var.rds_address}"
    rds_password = "${var.rds_password}"
    rds_username = "${var.rds_username}"
  }
}
