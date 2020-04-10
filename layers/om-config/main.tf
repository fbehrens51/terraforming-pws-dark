terraform {
  backend "s3" {
  }
}

provider "aws" {
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

data "terraform_remote_state" "pas" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "pas"
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
  secrets_bucket_name = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name

  smtp_host     = module.domains.smtp_fqdn
  smtp_port     = data.terraform_remote_state.bootstrap_postfix.outputs.smtp_client_port
  smtp_user     = data.terraform_remote_state.bootstrap_postfix.outputs.smtp_client_user
  smtp_password = data.terraform_remote_state.bootstrap_postfix.outputs.smtp_client_password
}

module "domains" {
  source = "../../modules/domains"

  root_domain = data.terraform_remote_state.paperwork.outputs.root_domain
}

module "splunk_ports" {
  source = "../../modules/splunk_ports"
}

data "aws_vpcs" "isolation_segment_vpcs" {
  tags = {
    Purpose  = "isolation-segment"
    env_name = var.env_name
  }
}

data "aws_subnet_ids" "isolation_segment_subnet_ids" {
  for_each = data.aws_vpcs.isolation_segment_vpcs.ids
  vpc_id   = each.key
}


data "aws_security_group" "isolation_segment_security_groups" {
  for_each = data.aws_vpcs.isolation_segment_vpcs.ids
  vpc_id   = each.key
  tags = {
    purpose = "vms-security-group"
  }
}

locals {
  isolation_segment_subnet_ids = flatten([for vpc_id, value in data.aws_subnet_ids.isolation_segment_subnet_ids : value.ids])

  isolation_segment_subnets = [for subnet in data.aws_subnet.isolation_segment_subnets : subnet if lookup(subnet.tags, "isolation_segment", "") != ""]

  isolation_segments = distinct([for s in local.isolation_segment_subnets : s.tags["isolation_segment"]])

  isolation_segments_subnet_cidrs = [for subnet in local.isolation_segment_subnets : subnet.cidr_block]

  isolation_segment_to_subnets = { for iso_seg in local.isolation_segments : iso_seg => [for s in local.isolation_segment_subnets : s if s.tags["isolation_segment"] == iso_seg] }
}

data "aws_subnet" "isolation_segment_subnets" {
  count = length(local.isolation_segment_subnet_ids)
  id    = local.isolation_segment_subnet_ids[count.index]
}

module "om_config" {
  source = "../../modules/ops_manager_config"

  secrets_bucket_name  = local.secrets_bucket_name
  cf_config            = var.cf_config
  cf_tools_config      = var.cf_tools_config
  director_config      = var.director_config
  portal_config        = var.portal_config
  om_create_db_config  = var.om_create_db_config
  om_drop_db_config    = var.om_drop_db_config
  om_syslog_config     = var.om_syslog_config
  om_ssl_config        = var.om_ssl_config
  om_ssh_banner_config = var.om_ssh_banner_config
  pas_vpc_dns          = local.vpc_dns
  env_name             = var.env_name
  region               = data.aws_region.current.name
  s3_endpoint          = var.s3_endpoint
  ec2_endpoint         = var.ec2_endpoint
  elb_endpoint         = var.elb_endpoint

  tsdb_instance_profile = data.terraform_remote_state.paperwork.outputs.tsdb_role_name

  volume_encryption_kms_key_arn = data.terraform_remote_state.paperwork.outputs.kms_key_arn

  isolation_segment_to_subnets         = local.isolation_segment_to_subnets
  isolation_segment_to_security_groups = data.aws_security_group.isolation_segment_security_groups

  errands_deploy_autoscaler           = "true"
  errands_deploy_notifications        = "true"
  errands_deploy_notifications_ui     = "true"
  errands_metric_registrar_smoke_test = "false"
  errands_nfsbrokerpush               = "false"
  errands_push_apps_manager           = "true"
  errands_push_usage_service          = "true"
  errands_smbbrokerpush               = "false"
  errands_smoke_tests                 = "true"
  errands_test_autoscaling            = "false"
  singleton_availability_zone         = var.singleton_availability_zone
  system_domain                       = data.terraform_remote_state.paperwork.outputs.system_domain
  apps_domain                         = data.terraform_remote_state.paperwork.outputs.apps_domain

  om_server_cert = data.terraform_remote_state.paperwork.outputs.om_server_cert
  om_server_key  = data.terraform_remote_state.paperwork.outputs.om_server_key

  password_policies_max_retry            = 5
  password_policies_expires_after_months = 0
  password_policies_min_length           = 0
  password_policies_min_lowercase        = 0
  password_policies_min_numeric          = 0
  password_policies_min_special          = 0
  password_policies_min_uppercase        = 0

  cloud_controller_encrypt_key_secret = var.cloud_controller_encrypt_key_secret
  credhub_encryption_password         = var.credhub_encryption_password

  router_elb_names = [
    data.terraform_remote_state.pas.outputs.pas_elb_id,
  ]

  director_blobstore_bucket        = data.terraform_remote_state.pas.outputs.director_blobstore_bucket

  vanity_cert_enabled    = var.vanity_cert_enabled
  vanity_cert_pem        = data.terraform_remote_state.paperwork.outputs.vanity_server_cert
  vanity_private_key_pem = data.terraform_remote_state.paperwork.outputs.vanity_server_key

  router_cert_pem                = data.terraform_remote_state.paperwork.outputs.router_server_cert
  router_private_key_pem         = data.terraform_remote_state.paperwork.outputs.router_server_key
  router_trusted_ca_certificates = data.terraform_remote_state.paperwork.outputs.router_trusted_ca_certs

  smtp_host       = local.smtp_host
  smtp_user       = local.smtp_user
  smtp_password   = local.smtp_password
  smtp_port       = local.smtp_port
  smtp_tls        = "true"
  smtp_from       = var.smtp_from
  smtp_recipients = var.smtp_recipients
  smtp_domain     = var.smtp_domain
  smtp_enabled    = var.smtp_enabled

  iaas_configuration_endpoints_ca_cert    = var.iaas_configuration_endpoints_ca_cert
  iaas_configuration_iam_instance_profile = data.terraform_remote_state.paperwork.outputs.director_role_name
  blobstore_instance_profile              = data.terraform_remote_state.paperwork.outputs.bucket_role_name

  uaa_service_provider_key_credentials_cert_pem        = data.terraform_remote_state.paperwork.outputs.uaa_server_cert
  uaa_service_provider_key_credentials_private_key_pem = data.terraform_remote_state.paperwork.outputs.uaa_server_key
  apps_manager_global_wrapper_footer_content           = var.apps_manager_global_wrapper_footer_content
  apps_manager_global_wrapper_header_content           = var.apps_manager_global_wrapper_header_content
  apps_manager_footer_text                             = "VMWare, Inc. All rights reserved"
  apps_manager_accent_color                            = "#172e3d"
  apps_manager_global_wrapper_text_color               = "#172e3d"
  apps_manager_company_name                            = "Tanzu Application Service"
  apps_manager_global_wrapper_bg_color                 = "#172e3d"
  apps_manager_favicon_file                            = "icons/apps_manager_favicon.png"
  apps_manager_square_logo_file                        = "icons/apps_manager_square_logo.png"
  apps_manager_main_logo_file                          = "icons/apps_manager_main_logo.png"
  apps_manager_tools_url                               = local.default_apps_manager_tools_url

  ntp_servers                                 = var.ntp_servers
  custom_ssh_banner                           = data.terraform_remote_state.paperwork.outputs.custom_ssh_banner
  security_configuration_trusted_certificates = data.terraform_remote_state.paperwork.outputs.trusted_with_additional_ca_certs

  rds_address     = data.terraform_remote_state.pas.outputs.rds_address
  rds_password    = data.terraform_remote_state.pas.outputs.rds_password
  rds_port        = data.terraform_remote_state.pas.outputs.rds_port
  rds_username    = data.terraform_remote_state.pas.outputs.rds_username
  rds_ca_cert_pem = data.terraform_remote_state.paperwork.outputs.rds_ca_cert

  kms_key_id                               = data.terraform_remote_state.paperwork.outputs.kms_key_id
  pas_buildpacks_bucket                    = data.terraform_remote_state.pas.outputs.pas_buildpacks_bucket
  pas_droplets_bucket                      = data.terraform_remote_state.pas.outputs.pas_droplets_bucket
  pas_packages_bucket                      = data.terraform_remote_state.pas.outputs.pas_packages_bucket
  pas_resources_bucket                     = data.terraform_remote_state.pas.outputs.pas_resources_bucket
  pas_buildpacks_backup_bucket             = data.terraform_remote_state.pas.outputs.pas_buildpacks_backup_bucket
  pas_droplets_backup_bucket               = data.terraform_remote_state.pas.outputs.pas_droplets_backup_bucket
  pas_packages_backup_bucket               = data.terraform_remote_state.pas.outputs.pas_packages_backup_bucket
  pas_resources_backup_bucket              = data.terraform_remote_state.pas.outputs.pas_resources_backup_bucket
  pas_subnet_cidrs                         = local.pas_ert_subnet_cidrs
  pas_subnet_availability_zones            = data.terraform_remote_state.pas.outputs.pas_subnet_availability_zones
  pas_subnet_gateways                      = data.terraform_remote_state.pas.outputs.pas_subnet_gateways
  pas_subnet_ids                           = data.terraform_remote_state.pas.outputs.pas_subnet_ids
  infrastructure_subnet_cidrs              = local.pas_infrastructure_subnet_cidrs
  infrastructure_subnet_availability_zones = data.terraform_remote_state.pas.outputs.infrastructure_subnet_availability_zones
  infrastructure_subnet_gateways           = data.terraform_remote_state.pas.outputs.infrastructure_subnet_gateways
  infrastructure_subnet_ids                = data.terraform_remote_state.pas.outputs.infrastructure_subnet_ids
  vms_security_group_id                    = data.terraform_remote_state.pas.outputs.vms_security_group_id
  ops_manager_ssh_public_key_name          = local.om_key_name
  ops_manager_ssh_private_key              = data.terraform_remote_state.pas.outputs.om_private_key_pem

  backup_restore_instance_type                = var.backup_restore_instance_type
  clock_global_instance_type                  = var.clock_global_instance_type
  cloud_controller_instance_type              = var.cloud_controller_instance_type
  cloud_controller_worker_instance_type       = var.cloud_controller_worker_instance_type
  consul_server_instance_type                 = var.consul_server_instance_type
  credhub_instance_type                       = var.credhub_instance_type
  diego_brain_instance_type                   = var.diego_brain_instance_type
  diego_cell_instance_type                    = var.diego_cell_instance_type
  diego_database_instance_type                = var.diego_database_instance_type
  doppler_instance_type                       = var.doppler_instance_type
  ha_proxy_instance_type                      = var.ha_proxy_instance_type
  loggregator_trafficcontroller_instance_type = var.loggregator_trafficcontroller_instance_type
  mysql_instance_type                         = var.mysql_instance_type
  mysql_monitor_instance_type                 = var.mysql_monitor_instance_type
  mysql_proxy_instance_type                   = var.mysql_proxy_instance_type
  nats_instance_type                          = var.nats_instance_type
  nfs_server_instance_type                    = var.nfs_server_instance_type
  router_instance_type                        = var.router_instance_type
  syslog_adapter_instance_type                = var.syslog_adapter_instance_type
  syslog_scheduler_instance_type              = var.syslog_scheduler_instance_type
  tcp_router_instance_type                    = var.tcp_router_instance_type
  uaa_instance_type                           = var.uaa_instance_type

  ldap_tls_ca_cert       = data.terraform_remote_state.paperwork.outputs.root_ca_cert
  ldap_tls_client_cert   = data.terraform_remote_state.paperwork.outputs.ldap_client_cert
  ldap_tls_client_key    = data.terraform_remote_state.paperwork.outputs.ldap_client_key
  smoke_test_client_cert = data.terraform_remote_state.paperwork.outputs.portal_smoke_test_cert
  smoke_test_client_key  = data.terraform_remote_state.paperwork.outputs.portal_smoke_test_key
  ldap_basedn            = data.terraform_remote_state.paperwork.outputs.ldap_basedn
  ldap_dn                = data.terraform_remote_state.paperwork.outputs.ldap_dn
  ldap_password          = data.terraform_remote_state.paperwork.outputs.ldap_password
  ldap_host              = data.terraform_remote_state.paperwork.outputs.ldap_host
  ldap_port              = data.terraform_remote_state.paperwork.outputs.ldap_port
  ldap_role_attr         = data.terraform_remote_state.paperwork.outputs.ldap_role_attr

  splunk_syslog_host    = module.domains.splunk_logs_fqdn
  splunk_syslog_port    = module.splunk_ports.splunk_tcp_port
  splunk_syslog_ca_cert = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs
}

module "runtime_config_config" {
  source = "../../modules/runtime_config"

  ipsec_log_level = "0"

  secrets_bucket_name   = local.secrets_bucket_name
  runtime_config        = var.runtime_config
  ipsec_subnet_cidrs    = local.ipsec_subnet_cidrs
  no_ipsec_subnet_cidrs = local.no_ipsec_subnet_cidrs

  custom_ssh_banner = data.terraform_remote_state.paperwork.outputs.custom_ssh_banner

  s3_endpoint = var.s3_endpoint
  region      = var.region

  extra_user_name       = var.extra_user_name
  extra_user_public_key = var.extra_user_public_key
  extra_user_sudo       = var.extra_user_sudo

  vpc_dns = local.vpc_dns
}

module "clamav_config" {
  source = "../../modules/clamav"

  secrets_bucket_name              = local.secrets_bucket_name
  clamav_addon_config              = var.clamav_addon_config
  clamav_mirror_config             = var.clamav_mirror_config
  bosh_network_name                = data.terraform_remote_state.paperwork.outputs.pas_network_name
  singleton_availability_zone      = var.singleton_availability_zone
  availability_zones               = data.terraform_remote_state.pas.outputs.pas_subnet_availability_zones
  clamav_no_upstream_mirror        = "false"
  clamav_external_mirrors          = var.clamav_external_mirrors
  clamav_cpu_limit                 = "50"
  clamav_enable_on_access_scanning = "false"
  clamav_mirror_instance_type      = var.clamav_mirror_instance_type
  s3_endpoint                      = var.s3_endpoint
  region                           = var.region
  splunk_syslog_host               = module.domains.splunk_logs_fqdn
  splunk_syslog_port               = module.splunk_ports.splunk_tcp_port
  splunk_syslog_ca_cert            = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs
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

locals {
  vpc_dns = data.terraform_remote_state.paperwork.outputs.pas_vpc_dns
  default_apps_manager_tools_url = format(
    "https://%s.%s",
    "cli",
    data.terraform_remote_state.paperwork.outputs.system_domain,
  )
  om_key_name = "${var.env_name}-om"

  pas_ert_subnet_cidrs            = data.terraform_remote_state.pas.outputs.pas_subnet_cidrs
  pas_infrastructure_subnet_cidrs = data.terraform_remote_state.pas.outputs.infrastructure_subnet_cidrs
  pas_rds_cidr_block              = data.terraform_remote_state.pas.outputs.rds_cidr_block
  pas_services_cidr_block         = data.terraform_remote_state.pas.outputs.services_cidr_block
  pas_public_cidr_block           = data.terraform_remote_state.pas.outputs.public_cidr_block
  enterprise_services_vpc_cidr    = data.aws_vpc.es_vpc.cidr_block
  control_plane_vpc_cidr          = data.aws_vpc.cp_vpc.cidr_block
  bastion_vpc_cidr                = data.aws_vpc.bastion_vpc.cidr_block

  ipsec_subnet_cidrs = concat(local.pas_ert_subnet_cidrs, local.isolation_segments_subnet_cidrs)
  no_ipsec_subnet_cidrs = concat(
    local.pas_infrastructure_subnet_cidrs,
    [
      local.pas_public_cidr_block,
      local.pas_services_cidr_block,
      local.pas_rds_cidr_block,
      local.enterprise_services_vpc_cidr,
      local.control_plane_vpc_cidr,
      local.bastion_vpc_cidr,
    ],
  )
}

