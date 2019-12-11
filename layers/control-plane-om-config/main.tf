terraform {
  backend "s3" {}
}

module "providers" {
  source = "../../modules/dark_providers"
}

data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "paperwork"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_splunk" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "bootstrap_splunk"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_control_plane" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "bootstrap_control_plane"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

data "aws_region" "current" {}

locals {
  mirror_bucket_name = "${data.terraform_remote_state.bootstrap_control_plane.mirror_bucket_name}"
}

data "aws_vpc" "bastion_vpc" {
  id = "${data.terraform_remote_state.paperwork.bastion_vpc_id}"
}

data "aws_vpc" "es_vpc" {
  id = "${data.terraform_remote_state.paperwork.es_vpc_id}"
}

data "aws_vpc" "cp_vpc" {
  id = "${data.terraform_remote_state.paperwork.cp_vpc_id}"
}

module "domains" {
  source = "../../modules/domains"

  root_domain = "${local.root_domain}"
}

module "splunk_ports" {
  source = "../../modules/splunk_ports"
}

module "om_config" {
  source = "../../modules/control_plane_ops_manager_config"

  control_plane_subnet_ids                = "${data.terraform_remote_state.bootstrap_control_plane.control_plane_subnet_ids}"
  vms_security_group_id                   = "${data.terraform_remote_state.bootstrap_control_plane.vms_security_group_id}"
  control_plane_subnet_availability_zones = "${data.terraform_remote_state.bootstrap_control_plane.control_plane_subnet_availability_zones}"
  control_plane_subnet_gateways           = "${data.terraform_remote_state.bootstrap_control_plane.control_plane_subnet_gateways}"
  control_plane_subnet_cidrs              = "${data.terraform_remote_state.bootstrap_control_plane.control_plane_subnet_cidrs}"
  control_plane_vpc_dns                   = "${data.terraform_remote_state.paperwork.control_plane_vpc_dns}"

  volume_encryption_kms_key_arn = "${data.terraform_remote_state.paperwork.kms_key_arn}"

  vpc_id       = "${local.vpc_id}"
  env_name     = "${var.env_name}"
  region       = "${data.aws_region.current.name}"
  s3_endpoint  = "${var.s3_endpoint}"
  ec2_endpoint = "${var.ec2_endpoint}"
  elb_endpoint = "${var.elb_endpoint}"

  singleton_availability_zone = "${var.singleton_availability_zone}"

  concourse_cert_pem        = "${data.terraform_remote_state.paperwork.concourse_server_cert}"
  concourse_private_key_pem = "${data.terraform_remote_state.paperwork.concourse_server_key}"
  concourse_users           = "${var.concourse_users}"

  root_domain = "${local.root_domain}"

  web_elb_names = ["${data.terraform_remote_state.bootstrap_control_plane.web_elb_id}"]

  smtp_host       = "${var.smtp_host}"
  smtp_user       = "${var.smtp_user}"
  smtp_password   = "${var.smtp_password}"
  smtp_tls        = "${var.smtp_tls}"
  smtp_from       = "${var.smtp_from}"
  smtp_port       = "${var.smtp_port}"
  smtp_recipients = "${var.smtp_recipients}"
  smtp_domain     = "${var.smtp_domain}"
  smtp_enabled    = "${var.smtp_enabled}"

  concourse_worker_role_name = "${data.terraform_remote_state.paperwork.platform_automation_engine_worker_role_name}"

  iaas_configuration_endpoints_ca_cert    = "${var.iaas_configuration_endpoints_ca_cert}"
  iaas_configuration_iam_instance_profile = "${data.terraform_remote_state.paperwork.director_role_name}"

  ntp_servers                                 = "${var.ntp_servers}"
  custom_ssh_banner                           = "${data.terraform_remote_state.paperwork.custom_ssh_banner}"
  security_configuration_trusted_certificates = "${data.terraform_remote_state.paperwork.trusted_with_additional_ca_certs}"

  # director_rds_address  = "${data.terraform_remote_state.bootstrap_control_plane.director_rds_address}"
  # director_rds_password = "${data.terraform_remote_state.bootstrap_control_plane.director_rds_password}"
  # director_rds_port     = "${data.terraform_remote_state.bootstrap_control_plane.director_rds_port}"
  # director_rds_username = "${data.terraform_remote_state.bootstrap_control_plane.director_rds_username}"

  # BOSH director database variables
  mysql_db_name  = "director"
  mysql_ca_cert  = "${data.terraform_remote_state.paperwork.rds_ca_cert}"
  mysql_host     = "${data.terraform_remote_state.bootstrap_control_plane.mysql_rds_address}"
  mysql_port     = "${data.terraform_remote_state.bootstrap_control_plane.mysql_rds_port}"
  mysql_username = "${data.terraform_remote_state.bootstrap_control_plane.mysql_rds_username}"
  mysql_password = "${data.terraform_remote_state.bootstrap_control_plane.mysql_rds_password}"
  # Concourse database variables
  postgres_db_name  = "concourse"
  postgres_ca_cert  = "${data.terraform_remote_state.paperwork.rds_ca_cert}"
  postgres_host     = "${data.terraform_remote_state.bootstrap_control_plane.postgres_rds_address}"
  postgres_port     = "${data.terraform_remote_state.bootstrap_control_plane.postgres_rds_port}"
  postgres_username = "${data.terraform_remote_state.bootstrap_control_plane.postgres_rds_username}"
  postgres_password = "${data.terraform_remote_state.bootstrap_control_plane.postgres_rds_password}"
  concourse_version = "${var.concourse_version}"

  # rds_ca_cert_pem = "${data.terraform_remote_state.paperwork.rds_ca_cert_pem}"

  ops_manager_ssh_public_key_name = "${local.om_key_name}"
  ops_manager_ssh_private_key     = "${data.terraform_remote_state.bootstrap_control_plane.om_private_key_pem}"

  # Used by the download config

  pivnet_api_token      = "${var.pivnet_api_token}"
  mirror_bucket_name    = "${local.mirror_bucket_name}"
  s3_endpoint           = "${var.s3_endpoint}"
  region                = "${var.region}"
  s3_access_key_id      = "${var.s3_access_key_id}"
  s3_secret_access_key  = "${var.s3_secret_access_key}"
  s3_auth_type          = "${var.s3_auth_type}"
  splunk_syslog_host    = "${module.domains.splunk_logs_fqdn}"
  splunk_syslog_port    = "${module.splunk_ports.splunk_tcp_port}"
  splunk_syslog_ca_cert = "${data.terraform_remote_state.paperwork.trusted_ca_certs}"
}

module "runtime_config_config" {
  source = "../../modules/runtime_config"

  runtime_config_product_version = "${var.runtime_config_product_version}"
  ipsec_log_level                = "${var.ipsec_log_level}"
  ipsec_optional                 = "${var.ipsec_optional}"

  ipsec_subnet_cidrs    = "${local.ipsec_subnet_cidrs}"
  no_ipsec_subnet_cidrs = "${local.no_ipsec_subnet_cidrs}"

  custom_ssh_banner = "${data.terraform_remote_state.paperwork.custom_ssh_banner}"

  pivnet_api_token     = "${var.pivnet_api_token}"
  mirror_bucket_name   = "${local.mirror_bucket_name}"
  s3_endpoint          = "${var.s3_endpoint}"
  region               = "${var.region}"
  s3_access_key_id     = "${var.s3_access_key_id}"
  s3_secret_access_key = "${var.s3_secret_access_key}"
  s3_auth_type         = "${var.s3_auth_type}"

  extra_user_name       = "${var.extra_user_name}"
  extra_user_public_key = "${var.extra_user_public_key}"
  extra_user_sudo       = "${var.extra_user_sudo}"

  vpc_dns = "${local.vpc_dns}"
}

module "clamav_config" {
  source = "../../modules/clamav"

  bosh_network_name                = "control-plane-subnet"
  singleton_availability_zone      = "${var.singleton_availability_zone}"
  availability_zones               = "${data.terraform_remote_state.bootstrap_control_plane.control_plane_subnet_availability_zones}"
  clamav_no_upstream_mirror        = "${var.clamav_no_upstream_mirror}"
  clamav_external_mirrors          = "${var.clamav_external_mirrors}"
  clamav_cpu_limit                 = "${var.clamav_cpu_limit}"
  clamav_enable_on_access_scanning = "${var.clamav_enable_on_access_scanning}"
  clamav_mirror_instance_type      = "${var.clamav_mirror_instance_type}"

  pivnet_api_token      = "${var.pivnet_api_token}"
  mirror_bucket_name    = "${local.mirror_bucket_name}"
  s3_endpoint           = "${var.s3_endpoint}"
  region                = "${var.region}"
  s3_access_key_id      = "${var.s3_access_key_id}"
  s3_secret_access_key  = "${var.s3_secret_access_key}"
  s3_auth_type          = "${var.s3_auth_type}"
  splunk_syslog_host    = "${module.domains.splunk_logs_fqdn}"
  splunk_syslog_port    = "${module.splunk_ports.splunk_tcp_port}"
  splunk_syslog_ca_cert = "${data.terraform_remote_state.paperwork.trusted_ca_certs}"
}

locals {
  vpc_dns     = "${data.terraform_remote_state.paperwork.pas_vpc_dns}"
  vpc_id      = "${data.terraform_remote_state.paperwork.pas_vpc_id}"
  om_key_name = "${var.env_name}-om"
  root_domain = "${data.terraform_remote_state.paperwork.root_domain}"

  control_plane_subnet_cidrs = "${data.terraform_remote_state.bootstrap_control_plane.control_plane_subnet_cidrs}"

  control_plane_public_cidrs   = "${data.terraform_remote_state.bootstrap_control_plane.control_plane_public_cidrs}"
  sjb_cidrs                    = "${data.terraform_remote_state.bootstrap_control_plane.sjb_cidr_block}"
  bosh_cidr                    = "${cidrhost(local.control_plane_subnet_cidrs[0], 5)}/32"
  enterprise_services_vpc_cidr = "${data.aws_vpc.es_vpc.cidr_block}"
  control_plane_vpc_cidr       = "${data.aws_vpc.cp_vpc.cidr_block}"
  bastion_vpc_cidr             = "${data.aws_vpc.bastion_vpc.cidr_block}"

  ipsec_subnet_cidrs    = "${local.control_plane_subnet_cidrs}"
  no_ipsec_subnet_cidrs = "${concat(local.control_plane_public_cidrs, list(local.bosh_cidr, local.enterprise_services_vpc_cidr, local.control_plane_vpc_cidr, local.bastion_vpc_cidr))}"
}
