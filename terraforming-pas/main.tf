locals {
  ops_man_subnet_id = "${var.om_public_subnet ? element(module.infra.public_subnet_ids, 0) : element(module.infra.infrastructure_subnet_ids, 0)}"

  bucket_suffix = "${random_integer.bucket.result}"

  default_tags = {
    Environment = "${var.env_name}"
    Application = "Cloud Foundry"
  }

  actual_tags = "${merge(var.tags, local.default_tags)}"
}

resource "random_integer" "bucket" {
  min = 1
  max = 100000
}

module "infra" {
  source = "../modules/infra"

  env_name           = "${var.env_name}"
  availability_zones = "${var.availability_zones}"

  internetless = "${var.internetless}"

  hosted_zone = "${var.hosted_zone}"
  dns_suffix  = "${var.dns_suffix}"

  tags = "${local.actual_tags}"
  use_route53 = "${var.use_route53}"
  vpc_id = "${var.vpc_id}"
}

module "ops_manager" {
  source = "../modules/ops_manager"

  vm_count       = "${var.ops_manager_vm ? 1 : 0}"
  optional_count = "${var.optional_ops_manager ? 1 : 0}"
  subnet_id      = "${local.ops_man_subnet_id}"

  env_name                 = "${var.env_name}"
  ami                      = "${var.ops_manager_ami}"
  optional_ami             = "${var.optional_ops_manager_ami}"
  instance_type            = "${var.ops_manager_instance_type}"
  private                  = "${var.ops_manager_private}"
  vpc_id                   = "${module.infra.vpc_id}"
  dns_suffix               = "${var.dns_suffix}"
  zone_id                  = "${module.infra.zone_id}"
  additional_iam_roles_arn = ["${module.pas.iam_pas_bucket_role_arn}"]
  bucket_suffix            = "${local.bucket_suffix}"
  ops_manager_role_name    = "${var.ops_manager_role_name}"
  om_eni                   = "${var.om_eni}"
  om_eip                   = "${var.om_eip}"

  tags = "${local.actual_tags}"
  use_route53 = "${var.use_route53}"
}

module "pas_certs" {
  source = "../modules/certs"

  subdomains = ["*.apps", "*.sys", "*.login.sys", "*.uaa.sys"]
  env_name   = "${var.env_name}"
  dns_suffix = "${var.dns_suffix}"

  ssl_cert           = "${var.ssl_cert}"
  ssl_private_key    = "${var.ssl_private_key}"
  ssl_ca_cert        = "${var.ssl_ca_cert}"
  ssl_ca_private_key = "${var.ssl_ca_private_key}"
}

module "isoseg_certs" {
  source = "../modules/certs"

  subdomains    = ["*.iso"]
  env_name      = "${var.env_name}"
  dns_suffix    = "${var.dns_suffix}"
  resource_name = "isoseg"

  ssl_cert           = "${var.isoseg_ssl_cert}"
  ssl_private_key    = "${var.isoseg_ssl_private_key}"
  ssl_ca_cert        = "${var.isoseg_ssl_ca_cert}"
  ssl_ca_private_key = "${var.isoseg_ssl_ca_private_key}"
}

module "pas" {
  source = "../modules/pas"

  env_name           = "${var.env_name}"
  availability_zones = "${var.availability_zones}"
  vpc_id             = "${module.infra.vpc_id}"
  route_table_ids    = "${module.infra.deployment_route_table_ids}"
  public_subnet_ids  = "${module.infra.public_subnet_ids}"
  internetless       = "${var.internetless}"

  bucket_suffix = "${local.bucket_suffix}"
  zone_id       = "${module.infra.zone_id}"
  dns_suffix    = "${var.dns_suffix}"

  create_backup_pas_buckets    = "${var.create_backup_pas_buckets}"
  create_versioned_pas_buckets = "${var.create_versioned_pas_buckets}"

  iam_ops_manager_role_name = "${module.ops_manager.ops_manager_iam_role_name}"
  pas_bucket_role_name      = "${var.pas_bucket_role_name}"

  create_isoseg_resources = "${var.create_isoseg_resources}"

  tags = "${local.actual_tags}"
  use_route53 = "${var.use_route53}"
  use_tcp_routes = "${var.use_tcp_routes}"
  use_ssh_routes = "${var.use_ssh_routes}"
}

module "rds" {
  source = "../modules/rds"

  rds_db_username    = "${var.rds_db_username}"
  rds_instance_class = "${var.rds_instance_class}"
  rds_instance_count = "${var.rds_instance_count}"

  engine         = "mariadb"
  engine_version = "10.1.31"
  db_port        = 3306

  env_name           = "${var.env_name}"
  availability_zones = "${var.availability_zones}"
  vpc_id             = "${module.infra.vpc_id}"
  tags               = "${local.actual_tags}"
}

module "om_config" {
  source = "../modules/ops_manager_config"

  pas_subnet_cidrs = "${module.pas.pas_subnet_cidrs}"
  rds_address = "${module.rds.rds_address}"
  rds_password = "${module.rds.rds_password}"
  rds_port = "${module.rds.rds_port}"
  rds_username = "${module.rds.rds_username}"
  pas_bucket_iam_instance_profile_name = "${module.pas.pas_bucket_iam_instance_profile_name}"
  pas_buildpacks_bucket = "${module.pas.pas_buildpacks_bucket}"
  pas_droplets_bucket = "${module.pas.pas_droplets_bucket}"
  pas_packages_bucket = "${module.pas.pas_packages_bucket}"
  pas_resources_bucket = "${module.pas.pas_resources_bucket}"
  pas_subnet_availability_zones = "${module.pas.pas_subnet_availability_zones}"
  pas_subnet_gateways = "${module.pas.pas_subnet_gateways}"
  pas_subnet_ids = "${module.pas.pas_subnet_ids}"
  vms_security_group_id = "${module.infra.vms_security_group_id}"
  region = "${module.infra.region}"
  ops_manager_ssh_public_key_name = "${module.ops_manager.ssh_public_key_name}"
  ops_manager_ssh_private_key = "${module.ops_manager.ssh_private_key}"
}

module "kms" {
  source = "../modules/kms/lookup"
  key_name = "${var.kms_key_name}"
}
