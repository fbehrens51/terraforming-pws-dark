terraform {
  backend "s3" {}
}

provider "aws" {}

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

data "terraform_remote_state" "pas" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "pas"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

data "aws_region" "current" {}

locals {
  mirror_bucket_name = "${data.terraform_remote_state.bootstrap_control_plane.mirror_bucket_name}"
}

module "domains" {
  source = "../../modules/domains"

  root_domain = "${data.terraform_remote_state.paperwork.root_domain}"
}

module "splunk_ports" {
  source = "../../modules/splunk_ports"
}

module "om_config" {
  source = "../../modules/ops_manager_config"

  pas_vpc_dns  = "${local.vpc_dns}"
  env_name     = "${var.env_name}"
  region       = "${data.aws_region.current.name}"
  s3_endpoint  = "${var.s3_endpoint}"
  ec2_endpoint = "${var.ec2_endpoint}"
  elb_endpoint = "${var.elb_endpoint}"

  volume_encryption_kms_key_arn = "${data.terraform_remote_state.paperwork.kms_key_arn}"

  errands_deploy_autoscaler           = "true"
  errands_deploy_notifications        = "true"
  errands_deploy_notifications_ui     = "true"
  errands_metric_registrar_smoke_test = "false"
  errands_nfsbrokerpush               = "false"
  errands_push_apps_manager           = "true"
  errands_push_usage_service          = "true"
  errands_smbbrokerpush               = "false"
  errands_smoke_tests                 = "true"
  errands_test_autoscaling            = "true"
  singleton_availability_zone         = "${var.singleton_availability_zone}"
  system_domain                       = "${data.terraform_remote_state.paperwork.system_domain}"
  apps_domain                         = "${data.terraform_remote_state.paperwork.apps_domain}"

  password_policies_max_retry            = 5
  password_policies_expires_after_months = 0
  password_policies_min_length           = 0
  password_policies_min_lowercase        = 0
  password_policies_min_numeric          = 0
  password_policies_min_special          = 0
  password_policies_min_uppercase        = 0

  cloud_controller_encrypt_key_secret = "${var.cloud_controller_encrypt_key_secret}"
  credhub_encryption_password         = "${var.credhub_encryption_password}"

  router_elb_names = [
    "${data.terraform_remote_state.pas.pas_elb_id}",
  ]

  router_cert_pem                = "${data.terraform_remote_state.paperwork.router_server_cert}"
  router_private_key_pem         = "${data.terraform_remote_state.paperwork.router_server_key}"
  router_trusted_ca_certificates = "${data.terraform_remote_state.paperwork.router_trusted_ca_certs}"

  smtp_host       = "${var.smtp_host}"
  smtp_user       = "${var.smtp_user}"
  smtp_password   = "${data.terraform_remote_state.paperwork.smtp_password}"
  smtp_tls        = "${var.smtp_tls}"
  smtp_from       = "${var.smtp_from}"
  smtp_port       = "${var.smtp_port}"
  smtp_recipients = "${var.smtp_recipients}"
  smtp_domain     = "${var.smtp_domain}"
  smtp_enabled    = "${var.smtp_enabled}"

  iaas_configuration_endpoints_ca_cert    = "${var.iaas_configuration_endpoints_ca_cert}"
  iaas_configuration_iam_instance_profile = "${data.terraform_remote_state.paperwork.director_role_name}"
  blobstore_instance_profile              = "${data.terraform_remote_state.paperwork.bucket_role_name}"

  uaa_service_provider_key_credentials_cert_pem        = "${data.terraform_remote_state.paperwork.uaa_server_cert}"
  uaa_service_provider_key_credentials_private_key_pem = "${data.terraform_remote_state.paperwork.uaa_server_key}"
  apps_manager_global_wrapper_footer_content           = "${var.apps_manager_global_wrapper_footer_content}"
  apps_manager_global_wrapper_header_content           = "${var.apps_manager_global_wrapper_header_content}"
  apps_manager_footer_text                             = "${var.apps_manager_footer_text}"
  apps_manager_accent_color                            = "${var.apps_manager_accent_color}"
  apps_manager_global_wrapper_text_color               = "${var.apps_manager_global_wrapper_text_color}"
  apps_manager_company_name                            = "${var.apps_manager_company_name}"
  apps_manager_global_wrapper_bg_color                 = "${var.apps_manager_global_wrapper_bg_color}"
  apps_manager_favicon_file                            = "${var.apps_manager_favicon_file}"
  apps_manager_square_logo_file                        = "${var.apps_manager_square_logo_file}"
  apps_manager_main_logo_file                          = "${var.apps_manager_main_logo_file}"
  apps_manager_tools_url                               = "${var.apps_manager_tools_url == "" ? local.default_apps_manager_tools_url : var.apps_manager_tools_url}"

  ntp_servers                                 = "${var.ntp_servers}"
  custom_ssh_banner                           = "${data.terraform_remote_state.paperwork.custom_ssh_banner}"
  security_configuration_trusted_certificates = "${data.terraform_remote_state.paperwork.trusted_with_additional_ca_certs}"

  rds_address     = "${data.terraform_remote_state.pas.rds_address}"
  rds_password    = "${data.terraform_remote_state.pas.rds_password}"
  rds_port        = "${data.terraform_remote_state.pas.rds_port}"
  rds_username    = "${data.terraform_remote_state.pas.rds_username}"
  rds_ca_cert_pem = "${data.terraform_remote_state.paperwork.rds_ca_cert}"

  kms_key_id                               = "${data.terraform_remote_state.paperwork.kms_key_id}"
  pas_buildpacks_bucket                    = "${data.terraform_remote_state.pas.pas_buildpacks_bucket}"
  pas_droplets_bucket                      = "${data.terraform_remote_state.pas.pas_droplets_bucket}"
  pas_packages_bucket                      = "${data.terraform_remote_state.pas.pas_packages_bucket}"
  pas_resources_bucket                     = "${data.terraform_remote_state.pas.pas_resources_bucket}"
  pas_subnet_cidrs                         = "${local.pas_ert_subnet_cidrs}"
  pas_subnet_availability_zones            = "${data.terraform_remote_state.pas.pas_subnet_availability_zones}"
  pas_subnet_gateways                      = "${data.terraform_remote_state.pas.pas_subnet_gateways}"
  pas_subnet_ids                           = "${data.terraform_remote_state.pas.pas_subnet_ids}"
  infrastructure_subnet_cidrs              = "${local.pas_infrastructure_subnet_cidrs}"
  infrastructure_subnet_availability_zones = "${data.terraform_remote_state.pas.infrastructure_subnet_availability_zones}"
  infrastructure_subnet_gateways           = "${data.terraform_remote_state.pas.infrastructure_subnet_gateways}"
  infrastructure_subnet_ids                = "${data.terraform_remote_state.pas.infrastructure_subnet_ids}"
  vms_security_group_id                    = "${data.terraform_remote_state.pas.vms_security_group_id}"
  ops_manager_ssh_public_key_name          = "${local.om_key_name}"
  ops_manager_ssh_private_key              = "${data.terraform_remote_state.pas.om_private_key_pem}"

  backup_restore_instance_type                = "${var.backup_restore_instance_type}"
  clock_global_instance_type                  = "${var.clock_global_instance_type}"
  cloud_controller_instance_type              = "${var.cloud_controller_instance_type}"
  cloud_controller_worker_instance_type       = "${var.cloud_controller_worker_instance_type}"
  consul_server_instance_type                 = "${var.consul_server_instance_type}"
  credhub_instance_type                       = "${var.credhub_instance_type}"
  diego_brain_instance_type                   = "${var.diego_brain_instance_type}"
  diego_cell_instance_type                    = "${var.diego_cell_instance_type}"
  diego_database_instance_type                = "${var.diego_database_instance_type}"
  doppler_instance_type                       = "${var.doppler_instance_type}"
  ha_proxy_instance_type                      = "${var.ha_proxy_instance_type}"
  loggregator_trafficcontroller_instance_type = "${var.loggregator_trafficcontroller_instance_type}"
  mysql_instance_type                         = "${var.mysql_instance_type}"
  mysql_monitor_instance_type                 = "${var.mysql_monitor_instance_type}"
  mysql_proxy_instance_type                   = "${var.mysql_proxy_instance_type}"
  nats_instance_type                          = "${var.nats_instance_type}"
  nfs_server_instance_type                    = "${var.nfs_server_instance_type}"
  router_instance_type                        = "${var.router_instance_type}"
  syslog_adapter_instance_type                = "${var.syslog_adapter_instance_type}"
  syslog_scheduler_instance_type              = "${var.syslog_scheduler_instance_type}"
  tcp_router_instance_type                    = "${var.tcp_router_instance_type}"
  uaa_instance_type                           = "${var.uaa_instance_type}"

  jwt_expiration         = "${var.jwt_expiration}"
  ldap_tls_ca_cert       = "${data.terraform_remote_state.paperwork.root_ca_cert}"
  ldap_tls_client_cert   = "${data.terraform_remote_state.paperwork.ldap_client_cert}"
  ldap_tls_client_key    = "${data.terraform_remote_state.paperwork.ldap_client_key}"
  smoke_test_client_cert = "${data.terraform_remote_state.paperwork.portal_smoke_test_cert}"
  smoke_test_client_key  = "${data.terraform_remote_state.paperwork.portal_smoke_test_key}"
  ldap_basedn            = "${data.terraform_remote_state.paperwork.ldap_basedn}"
  ldap_dn                = "${data.terraform_remote_state.paperwork.ldap_dn}"
  ldap_password          = "${data.terraform_remote_state.paperwork.ldap_password}"
  ldap_host              = "${data.terraform_remote_state.paperwork.ldap_host}"
  ldap_port              = "${data.terraform_remote_state.paperwork.ldap_port}"
  ldap_role_attr         = "${data.terraform_remote_state.paperwork.ldap_role_attr}"

  pivnet_api_token         = "${var.pivnet_api_token}"
  mirror_bucket_name       = "${local.mirror_bucket_name}"
  s3_endpoint              = "${var.s3_endpoint}"
  region                   = "${var.region}"
  portal_product_version   = "${var.portal_product_version}"
  cf_tools_product_version = "${var.cf_tools_product_version}"
  s3_access_key_id         = "${var.s3_access_key_id}"
  s3_secret_access_key     = "${var.s3_secret_access_key}"
  s3_auth_type             = "${var.s3_auth_type}"

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

  bosh_network_name                = "pas"
  singleton_availability_zone      = "${var.singleton_availability_zone}"
  availability_zones               = "${data.terraform_remote_state.pas.pas_subnet_availability_zones}"
  clamav_no_upstream_mirror        = "${var.clamav_no_upstream_mirror}"
  clamav_external_mirrors          = "${var.clamav_external_mirrors}"
  clamav_cpu_limit                 = "${var.clamav_cpu_limit}"
  clamav_enable_on_access_scanning = "${var.clamav_enable_on_access_scanning}"
  clamav_mirror_instance_type      = "${var.clamav_mirror_instance_type}"
  pivnet_api_token                 = "${var.pivnet_api_token}"
  mirror_bucket_name               = "${local.mirror_bucket_name}"
  s3_endpoint                      = "${var.s3_endpoint}"
  region                           = "${var.region}"
  s3_access_key_id                 = "${var.s3_access_key_id}"
  s3_secret_access_key             = "${var.s3_secret_access_key}"
  s3_auth_type                     = "${var.s3_auth_type}"
  splunk_syslog_host               = "${module.domains.splunk_logs_fqdn}"
  splunk_syslog_port               = "${module.splunk_ports.splunk_tcp_port}"
  splunk_syslog_ca_cert            = "${data.terraform_remote_state.paperwork.trusted_ca_certs}"
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

locals {
  vpc_dns                        = "${data.terraform_remote_state.paperwork.pas_vpc_dns}"
  default_apps_manager_tools_url = "${format("https://%s.%s", "cli", data.terraform_remote_state.paperwork.system_domain)}"
  om_key_name                    = "${var.env_name}-om"

  pas_ert_subnet_cidrs            = "${data.terraform_remote_state.pas.pas_subnet_cidrs}"
  pas_infrastructure_subnet_cidrs = "${data.terraform_remote_state.pas.infrastructure_subnet_cidrs}"
  pas_rds_cidr_block              = "${data.terraform_remote_state.pas.rds_cidr_block}"
  pas_services_cidr_block         = "${data.terraform_remote_state.pas.services_cidr_block}"
  pas_public_cidr_block           = "${data.terraform_remote_state.pas.public_cidr_block}"
  enterprise_services_vpc_cidr    = "${data.aws_vpc.es_vpc.cidr_block}"
  control_plane_vpc_cidr          = "${data.aws_vpc.cp_vpc.cidr_block}"
  bastion_vpc_cidr                = "${data.aws_vpc.bastion_vpc.cidr_block}"

  ipsec_subnet_cidrs    = "${local.pas_ert_subnet_cidrs}"
  no_ipsec_subnet_cidrs = "${concat(local.pas_infrastructure_subnet_cidrs, list(local.pas_public_cidr_block, local.pas_services_cidr_block, local.pas_rds_cidr_block, local.enterprise_services_vpc_cidr, local.control_plane_vpc_cidr, local.bastion_vpc_cidr))}"
}
