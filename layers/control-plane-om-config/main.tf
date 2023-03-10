data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "paperwork"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "scaling-params" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "scaling-params"
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

data "terraform_remote_state" "bootstrap_control_plane_foundation" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_control_plane_foundation"
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

module "syslog_ports" {
  source = "../../modules/syslog_ports"
}

data "aws_network_interface" "ec2_vpce_eni" {
  for_each = local.ec2_vpce_eni_ids
  filter {
    name   = "network-interface-id"
    values = [each.value]
  }
}

module "om_config" {
  source = "../../modules/control_plane_ops_manager_config"

  scale                                   = data.terraform_remote_state.scaling-params.outputs.instance_types
  secrets_bucket_name                     = local.secrets_bucket_name
  director_config                         = var.director_config
  concourse_config                        = var.concourse_config
  worker_config                           = var.worker_config
  om_create_db_config                     = var.om_create_db_config
  om_syslog_config                        = var.om_syslog_config
  om_tokens_expiration_config             = var.om_tokens_expiration_config
  om_ssl_config                           = var.om_ssl_config
  om_ssh_banner_config                    = var.om_ssh_banner_config
  om_uaa_password_policy_config           = var.om_uaa_password_policy_config
  control_plane_subnet_ids                = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_ids
  vms_security_group_id                   = data.terraform_remote_state.bootstrap_control_plane.outputs.vms_security_group_id
  control_plane_subnet_availability_zones = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_availability_zones
  control_plane_subnet_gateways           = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_gateways
  control_plane_subnet_cidrs              = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_private_subnet_cidrs
  control_plane_vpc_dns                   = join(", ", data.terraform_remote_state.paperwork.outputs.enterprise_dns)
  control_plane_additional_reserved_ips   = local.ec2_vpce_subnet_ip_map

  volume_encryption_kms_key_arn = data.terraform_remote_state.paperwork.outputs.kms_key_arn

  control_plane_star_server_cert = data.terraform_remote_state.paperwork.outputs.control_plane_star_server_cert
  control_plane_star_server_key  = data.terraform_remote_state.paperwork.outputs.control_plane_star_server_key

  vpc_id       = local.vpc_id
  env_name     = yamlencode({ env : var.global_vars.env_name, iaas : join("_", [data.terraform_remote_state.paperwork.outputs.foundation_name, "cp"]), foundation_name : data.terraform_remote_state.paperwork.outputs.foundation_name })
  region       = data.aws_region.current.name
  s3_endpoint  = var.s3_endpoint
  ec2_endpoint = var.ec2_endpoint
  elb_endpoint = var.elb_endpoint

  singleton_availability_zone = var.singleton_availability_zone

  ca_certificate            = data.terraform_remote_state.paperwork.outputs.concourse_ca_certs_bundle
  concourse_cert_pem        = data.terraform_remote_state.paperwork.outputs.control_plane_star_server_cert
  concourse_private_key_pem = data.terraform_remote_state.paperwork.outputs.control_plane_star_server_key
  admin_users               = var.admin_users
  uaa_cert_pem              = data.terraform_remote_state.paperwork.outputs.control_plane_star_server_cert
  uaa_private_key_pem       = data.terraform_remote_state.paperwork.outputs.control_plane_star_server_key
  credhub_cert_pem          = data.terraform_remote_state.paperwork.outputs.control_plane_star_server_cert
  credhub_private_key_pem   = data.terraform_remote_state.paperwork.outputs.control_plane_star_server_key

  root_domain = local.root_domain

  uaa_tg_names                   = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.uaa_tg_ids
  web_tg_names                   = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.web_tg_ids
  uaa_elb_names                  = [data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.uaa_elb_id]
  credhub_elb_names              = [data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.credhub_elb_id]
  credhub_tg_names               = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.credhub_tg_ids
  concourse_lb_security_group_id = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.concourse_lb_security_group_id
  credhub_lb_security_group_id   = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.credhub_lb_security_group_id
  uaa_lb_security_group_id       = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.uaa_lb_security_group_id

  password_policies_max_retry            = var.password_policies_max_retry
  password_policies_expires_after_months = var.password_policies_expires_after_months
  password_policies_min_length           = var.password_policies_min_length
  password_policies_min_lowercase        = var.password_policies_min_lowercase
  password_policies_min_numeric          = var.password_policies_min_numeric
  password_policies_min_special          = var.password_policies_min_special
  password_policies_min_uppercase        = var.password_policies_min_uppercase

  smtp_host       = module.domains.smtp_fqdn
  smtp_user       = data.terraform_remote_state.bootstrap_postfix.outputs.smtp_client_user
  smtp_password   = data.terraform_remote_state.bootstrap_postfix.outputs.smtp_client_password
  smtp_port       = data.terraform_remote_state.bootstrap_postfix.outputs.smtp_client_port
  smtp_tls        = "true"
  smtp_from       = var.smtp_from
  smtp_recipients = var.smtp_recipients
  smtp_domain     = var.smtp_domain
  smtp_enabled    = var.smtp_enabled

  concourse_worker_role_name = data.terraform_remote_state.paperwork.outputs.bootstrap_role_name

  iaas_configuration_endpoints_ca_cert    = data.terraform_remote_state.paperwork.outputs.iaas_trusted_ca_certs
  iaas_configuration_iam_instance_profile = data.terraform_remote_state.paperwork.outputs.foundation_role_name
  blobstore_instance_profile              = data.terraform_remote_state.paperwork.outputs.bucket_role_name

  ntp_servers                                 = var.ntp_servers
  custom_ssh_banner                           = data.terraform_remote_state.paperwork.outputs.custom_ssh_banner
  security_configuration_trusted_certificates = data.terraform_remote_state.paperwork.outputs.bosh_system_ca_bundle

  director_blobstore_bucket   = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.director_blobstore_bucket
  director_blobstore_location = var.director_blobstore_location

  # director_rds_address  = "${data.terraform_remote_state.bootstrap_control_plane_foundation.director_rds_address}"
  # director_rds_password = "${data.terraform_remote_state.bootstrap_control_plane_foundation.director_rds_password}"
  # director_rds_port     = "${data.terraform_remote_state.bootstrap_control_plane_foundation.director_rds_port}"
  # director_rds_username = "${data.terraform_remote_state.bootstrap_control_plane_foundation.director_rds_username}"

  # BOSH director database variables
  mysql_db_name  = "director"
  mysql_ca_cert  = data.terraform_remote_state.paperwork.outputs.rds_ca_cert
  mysql_host     = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.mysql_rds_address
  mysql_port     = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.mysql_rds_port
  mysql_username = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.mysql_rds_username
  mysql_password = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.mysql_rds_password

  # Concourse database variables
  postgres_db_name      = "concourse"
  postgres_uaa_db_name  = "uaa"
  postgres_uaa_username = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.postgres_rds_username
  postgres_uaa_password = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.postgres_rds_password
  postgres_ca_cert      = data.terraform_remote_state.paperwork.outputs.rds_ca_cert
  postgres_host         = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.postgres_rds_address
  postgres_port         = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.postgres_rds_port
  postgres_username     = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.postgres_rds_username
  postgres_password     = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.postgres_rds_password

  # Credhub database variables
  postgres_credhub_db_name  = "credhub"
  postgres_credhub_username = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.postgres_rds_username
  postgres_credhub_password = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.postgres_rds_password

  # rds_ca_cert_pem = "${data.terraform_remote_state.paperwork.rds_ca_cert_pem}"

  ops_manager_ssh_public_key_name = local.om_key_name
  ops_manager_ssh_private_key     = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.om_private_key_pem

  # Used by the download config

  syslog_host    = module.domains.fluentd_fqdn
  syslog_port    = module.syslog_ports.syslog_port
  syslog_ca_cert = data.terraform_remote_state.paperwork.outputs.syslog_ca_certs_bundle

  forwarders = [
    {
      domain        = data.terraform_remote_state.paperwork.outputs.endpoint_domain
      forwarder_ips = [cidrhost(data.aws_vpc.cp_vpc.cidr_block, 2)]
    }
  ]

  extra_users = data.terraform_remote_state.paperwork.outputs.extra_bosh_users
  disk_type   = var.disk_type
}

module "runtime_config_config" {
  source              = "../../modules/runtime_config"
  secrets_bucket_name = local.secrets_bucket_name
  runtime_config      = var.runtime_config
  custom_ssh_banner   = data.terraform_remote_state.paperwork.outputs.custom_ssh_banner
  s3_endpoint         = var.s3_endpoint
  region              = var.region
  extra_users         = data.terraform_remote_state.paperwork.outputs.extra_bosh_users
}

module "clamav_config" {
  source = "../../modules/clamav"

  scale                            = data.terraform_remote_state.scaling-params.outputs.instance_types
  secrets_bucket_name              = local.secrets_bucket_name
  clamav_addon_config              = var.clamav_addon_config
  clamav_mirror_config             = var.clamav_mirror_config
  clamav_director_config           = var.clamav_director_config
  bosh_network_name                = data.terraform_remote_state.paperwork.outputs.control_plane_subnet_network_name
  singleton_availability_zone      = var.singleton_availability_zone
  availability_zones               = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_availability_zones
  clamav_no_upstream_mirror        = "false"
  clamav_external_mirrors          = var.clamav_external_mirrors
  clamav_cpu_limit                 = "50"
  clamav_enable_on_access_scanning = "false"
  clamav_release_url               = var.clamav_release_url
  clamav_release_sha1              = var.clamav_release_sha1
  s3_endpoint                      = var.s3_endpoint
  region                           = var.region
  syslog_host                      = module.domains.fluentd_fqdn
  syslog_port                      = module.syslog_ports.syslog_port
  syslog_ca_cert                   = data.terraform_remote_state.paperwork.outputs.syslog_ca_certs_bundle
}

locals {
  vpc_id          = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
  env_name_prefix = var.global_vars.name_prefix
  om_key_name     = "${local.env_name_prefix}-om"
  root_domain     = data.terraform_remote_state.paperwork.outputs.root_domain

  control_plane_private_subnet_cidrs = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_private_subnet_cidrs

  control_plane_public_cidrs   = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_public_cidrs
  sjb_cidrs                    = data.terraform_remote_state.bootstrap_control_plane.outputs.sjb_cidr_block
  bosh_cidr                    = "${cidrhost(local.control_plane_private_subnet_cidrs[0], 5)}/32"
  enterprise_services_vpc_cidr = data.aws_vpc.es_vpc.cidr_block
  control_plane_vpc_cidr       = data.aws_vpc.cp_vpc.cidr_block
  bastion_vpc_cidr             = data.aws_vpc.bastion_vpc.cidr_block

  ipsec_subnet_cidrs = local.control_plane_private_subnet_cidrs
  no_ipsec_subnet_cidrs = concat(
    local.control_plane_public_cidrs,
    [
      local.bosh_cidr,
      local.enterprise_services_vpc_cidr,
      local.bastion_vpc_cidr,
    ],
  )

  ec2_vpce_eni_ids = data.terraform_remote_state.bootstrap_control_plane.outputs.ec2_vpce_eni_ids

  ec2_vpce_subnet_ip_map = {
    for eni in data.aws_network_interface.ec2_vpce_eni :
    eni.subnet_id => eni.private_ip
  }

}

