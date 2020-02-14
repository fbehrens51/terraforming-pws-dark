terraform {
  backend "s3" {
  }
}

module "providers" {
  source = "../../modules/dark_providers"
}

data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "paperwork"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_splunk" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_splunk"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_control_plane" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_control_plane"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_postfix" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_postfix"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "aws_region" "current" {
}

locals {
  mirror_bucket_name = data.terraform_remote_state.bootstrap_control_plane.outputs.mirror_bucket_name

  smtp_host     = module.domains.smtp_fqdn
  smtp_port     = data.terraform_remote_state.bootstrap_postfix.outputs.smtp_client_port
  smtp_user     = data.terraform_remote_state.bootstrap_postfix.outputs.smtp_client_user
  smtp_password = data.terraform_remote_state.bootstrap_postfix.outputs.smtp_client_password
}

data "aws_vpc" "bastion_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.bastion_vpc_id
}

data "aws_vpc" "es_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.es_vpc_id
}

data "aws_vpc" "cp_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.cp_vpc_id
}

module "domains" {
  source = "../../modules/domains"

  root_domain = local.root_domain
}

module "splunk_ports" {
  source = "../../modules/splunk_ports"
}

module "om_config" {
  source = "../../modules/control_plane_ops_manager_config"

  control_plane_subnet_ids                = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_ids
  vms_security_group_id                   = data.terraform_remote_state.bootstrap_control_plane.outputs.vms_security_group_id
  control_plane_subnet_availability_zones = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_availability_zones
  control_plane_subnet_gateways           = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_gateways
  control_plane_subnet_cidrs              = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_cidrs
  control_plane_vpc_dns                   = data.terraform_remote_state.paperwork.outputs.control_plane_vpc_dns

  volume_encryption_kms_key_arn = data.terraform_remote_state.paperwork.outputs.kms_key_arn

  vpc_id       = local.vpc_id
  env_name     = var.env_name
  region       = data.aws_region.current.name
  s3_endpoint  = var.s3_endpoint
  ec2_endpoint = var.ec2_endpoint
  elb_endpoint = var.elb_endpoint

  singleton_availability_zone = var.singleton_availability_zone

  concourse_cert_pem        = data.terraform_remote_state.paperwork.outputs.concourse_server_cert
  concourse_private_key_pem = data.terraform_remote_state.paperwork.outputs.concourse_server_key
  concourse_users           = var.concourse_users

  root_domain = local.root_domain

  web_elb_names = [data.terraform_remote_state.bootstrap_control_plane.outputs.web_elb_id]

  smtp_host       = local.smtp_host
  smtp_user       = local.smtp_user
  smtp_password   = local.smtp_password
  smtp_port       = local.smtp_port
  smtp_tls        = "true"
  smtp_from       = var.smtp_from
  smtp_recipients = var.smtp_recipients
  smtp_domain     = var.smtp_domain
  smtp_enabled    = var.smtp_enabled

  concourse_worker_role_name = data.terraform_remote_state.paperwork.outputs.platform_automation_engine_worker_role_name

  iaas_configuration_endpoints_ca_cert    = var.iaas_configuration_endpoints_ca_cert
  iaas_configuration_iam_instance_profile = data.terraform_remote_state.paperwork.outputs.director_role_name

  ntp_servers                                 = var.ntp_servers
  custom_ssh_banner                           = data.terraform_remote_state.paperwork.outputs.custom_ssh_banner
  security_configuration_trusted_certificates = data.terraform_remote_state.paperwork.outputs.trusted_with_additional_ca_certs

  # director_rds_address  = "${data.terraform_remote_state.bootstrap_control_plane.director_rds_address}"
  # director_rds_password = "${data.terraform_remote_state.bootstrap_control_plane.director_rds_password}"
  # director_rds_port     = "${data.terraform_remote_state.bootstrap_control_plane.director_rds_port}"
  # director_rds_username = "${data.terraform_remote_state.bootstrap_control_plane.director_rds_username}"

  # BOSH director database variables
  mysql_db_name  = "director"
  mysql_ca_cert  = data.terraform_remote_state.paperwork.outputs.rds_ca_cert
  mysql_host     = data.terraform_remote_state.bootstrap_control_plane.outputs.mysql_rds_address
  mysql_port     = data.terraform_remote_state.bootstrap_control_plane.outputs.mysql_rds_port
  mysql_username = data.terraform_remote_state.bootstrap_control_plane.outputs.mysql_rds_username
  mysql_password = data.terraform_remote_state.bootstrap_control_plane.outputs.mysql_rds_password

  # Concourse database variables
  postgres_db_name  = "concourse"
  postgres_ca_cert  = data.terraform_remote_state.paperwork.outputs.rds_ca_cert
  postgres_host     = data.terraform_remote_state.bootstrap_control_plane.outputs.postgres_rds_address
  postgres_port     = data.terraform_remote_state.bootstrap_control_plane.outputs.postgres_rds_port
  postgres_username = data.terraform_remote_state.bootstrap_control_plane.outputs.postgres_rds_username
  postgres_password = data.terraform_remote_state.bootstrap_control_plane.outputs.postgres_rds_password

  # rds_ca_cert_pem = "${data.terraform_remote_state.paperwork.rds_ca_cert_pem}"

  ops_manager_ssh_public_key_name = local.om_key_name
  ops_manager_ssh_private_key     = data.terraform_remote_state.bootstrap_control_plane.outputs.om_private_key_pem

  # Used by the download config

  mirror_bucket_name    = local.mirror_bucket_name
  splunk_syslog_host    = module.domains.splunk_logs_fqdn
  splunk_syslog_port    = module.splunk_ports.splunk_tcp_port
  splunk_syslog_ca_cert = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs
}

module "runtime_config_config" {
  source = "../../modules/runtime_config"

  ipsec_log_level                = var.ipsec_log_level

  ipsec_subnet_cidrs    = local.ipsec_subnet_cidrs
  no_ipsec_subnet_cidrs = local.no_ipsec_subnet_cidrs

  custom_ssh_banner = data.terraform_remote_state.paperwork.outputs.custom_ssh_banner

  mirror_bucket_name = local.mirror_bucket_name
  s3_endpoint        = var.s3_endpoint
  region             = var.region

  extra_user_name       = var.extra_user_name
  extra_user_public_key = var.extra_user_public_key
  extra_user_sudo       = var.extra_user_sudo

  vpc_dns = local.vpc_dns
}

module "clamav_config" {
  source = "../../modules/clamav"

  bosh_network_name                = "control-plane-subnet"
  singleton_availability_zone      = var.singleton_availability_zone
  availability_zones               = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_availability_zones
  clamav_no_upstream_mirror        = var.clamav_no_upstream_mirror
  clamav_external_mirrors          = var.clamav_external_mirrors
  clamav_cpu_limit                 = var.clamav_cpu_limit
  clamav_enable_on_access_scanning = var.clamav_enable_on_access_scanning
  clamav_mirror_instance_type      = var.clamav_mirror_instance_type

  mirror_bucket_name    = local.mirror_bucket_name
  s3_endpoint           = var.s3_endpoint
  region                = var.region
  splunk_syslog_host    = module.domains.splunk_logs_fqdn
  splunk_syslog_port    = module.splunk_ports.splunk_tcp_port
  splunk_syslog_ca_cert = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs
}

locals {
  vpc_dns     = data.terraform_remote_state.paperwork.outputs.pas_vpc_dns
  vpc_id      = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
  om_key_name = "${var.env_name}-om"
  root_domain = data.terraform_remote_state.paperwork.outputs.root_domain

  control_plane_subnet_cidrs = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_cidrs

  control_plane_public_cidrs   = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_public_cidrs
  sjb_cidrs                    = data.terraform_remote_state.bootstrap_control_plane.outputs.sjb_cidr_block
  bosh_cidr                    = "${cidrhost(local.control_plane_subnet_cidrs[0], 5)}/32"
  enterprise_services_vpc_cidr = data.aws_vpc.es_vpc.cidr_block
  control_plane_vpc_cidr       = data.aws_vpc.cp_vpc.cidr_block
  bastion_vpc_cidr             = data.aws_vpc.bastion_vpc.cidr_block

  ipsec_subnet_cidrs = local.control_plane_subnet_cidrs
  no_ipsec_subnet_cidrs = concat(
    local.control_plane_public_cidrs,
    [
      local.bosh_cidr,
      local.enterprise_services_vpc_cidr,
      local.bastion_vpc_cidr,
    ],
  )
}

