terraform {
  backend "s3" {}
}

provider "aws" {
  region = "${var.region}"
}

module "providers" {
  source = "../../modules/dark_providers"
}

data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "layer0-paperwork"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

data "terraform_remote_state" "ldap" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "layer2-ldap-server"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

data "terraform_remote_state" "pas" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "layer3-pas"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

data "aws_region" "current" {}

module "om_config" {
  source = "../../modules/ops_manager_config"

  vpc_id       = "${local.vpc_id}"
  env_name     = "${var.env_name}"
  region       = "${data.aws_region.current.name}"
  s3_endpoint  = "${var.s3_endpoint}"
  ec2_endpoint = "${var.ec2_endpoint}"
  elb_endpoint = "${var.elb_endpoint}"

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
  system_domain                       = "${var.system_domain}"
  apps_domain                         = "${var.apps_domain}"

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

  router_cert_pem_file                = "${var.router_cert_pem_file}"
  router_private_key_pem_file         = "${var.router_private_key_pem_file}"
  router_trusted_ca_certificates_file = "${var.router_trusted_ca_certificates_file}"

  smtp_host       = "${var.smtp_host}"
  smtp_user       = "${var.smtp_user}"
  smtp_password   = "${var.smtp_password}"
  smtp_tls        = "${var.smtp_tls}"
  smtp_from       = "${var.smtp_from}"
  smtp_port       = "${var.smtp_port}"
  smtp_recipients = "${var.smtp_recipients}"
  smtp_domain     = "${var.smtp_domain}"
  smtp_enabled    = "${var.smtp_enabled}"

  //TODO see https://www.pivotaltracker.com/story/show/166098713
  iaas_configuration_endpoints_ca_cert    = "${var.iaas_configuration_endpoints_ca_cert}"
  iaas_configuration_iam_instance_profile = "${data.terraform_remote_state.paperwork.director_role_name}"
  blobstore_instance_profile              = "${data.terraform_remote_state.paperwork.bucket_role_name}"

  uaa_service_provider_key_credentials_cert_pem_file        = "${var.uaa_service_provider_key_credentials_cert_pem_file}"
  uaa_service_provider_key_credentials_private_key_pem_file = "${var.uaa_service_provider_key_credentials_private_key_pem_file}"
  apps_manager_global_wrapper_footer_content                = "${var.apps_manager_global_wrapper_footer_content}"
  apps_manager_global_wrapper_header_content                = "${var.apps_manager_global_wrapper_header_content}"
  apps_manager_footer_text                                  = "${var.apps_manager_footer_text}"
  apps_manager_accent_color                                 = "${var.apps_manager_accent_color}"
  apps_manager_global_wrapper_text_color                    = "${var.apps_manager_global_wrapper_text_color}"
  apps_manager_company_name                                 = "${var.apps_manager_company_name}"
  apps_manager_global_wrapper_bg_color                      = "${var.apps_manager_global_wrapper_bg_color}"
  apps_manager_favicon_file                                 = "${var.apps_manager_favicon_file}"
  apps_manager_square_logo_file                             = "${var.apps_manager_square_logo_file}"
  apps_manager_main_logo_file                               = "${var.apps_manager_main_logo_file}"

  ntp_servers                                 = "${var.ntp_servers}"
  custom_ssh_banner_file                      = "${var.custom_ssh_banner_file}"
  security_configuration_trusted_certificates = "${var.security_configuration_trusted_certificates}"

  rds_address      = "${data.terraform_remote_state.pas.rds_address}"
  rds_password     = "${data.terraform_remote_state.pas.rds_password}"
  rds_port         = "${data.terraform_remote_state.pas.rds_port}"
  rds_username     = "${data.terraform_remote_state.pas.rds_username}"
  rds_ca_cert_file = "${var.rds_ca_cert_file}"

  pas_bucket_iam_instance_profile_name = "${data.terraform_remote_state.paperwork.bucket_role_name}"
  pas_buildpacks_bucket                = "${data.terraform_remote_state.pas.pas_buildpacks_bucket}"
  pas_droplets_bucket                  = "${data.terraform_remote_state.pas.pas_droplets_bucket}"
  pas_packages_bucket                  = "${data.terraform_remote_state.pas.pas_packages_bucket}"
  pas_resources_bucket                 = "${data.terraform_remote_state.pas.pas_resources_bucket}"
  pas_subnet_cidrs                     = "${data.terraform_remote_state.pas.pas_subnet_cidrs}"
  pas_subnet_availability_zones        = "${data.terraform_remote_state.pas.pas_subnet_availability_zones}"
  pas_subnet_gateways                  = "${data.terraform_remote_state.pas.pas_subnet_gateways}"
  pas_subnet_ids                       = "${data.terraform_remote_state.pas.pas_subnet_ids}"
  vms_security_group_id                = "${data.terraform_remote_state.pas.vms_security_group_id}"
  ops_manager_ssh_public_key_name      = "${local.om_key_name}"
  ops_manager_ssh_private_key          = "${data.terraform_remote_state.pas.om_private_key_pem}"

  jwt_expiration              = "${var.jwt_expiration}"
  ldap_tls_ca_cert            = "${data.terraform_remote_state.ldap.ca_cert}"
  ldap_tls_client_cert        = "${data.terraform_remote_state.ldap.client_cert}"
  ldap_tls_client_key         = "${data.terraform_remote_state.ldap.client_key}"
  smoke_test_client_cert_file = "${var.smoke_test_client_cert_file}"
  smoke_test_client_key_file  = "${var.smoke_test_client_key_file}"
  ldap_basedn                 = "${data.terraform_remote_state.ldap.basedn}"
  ldap_dn                     = "${data.terraform_remote_state.ldap.dn}"
  ldap_password               = "${data.terraform_remote_state.ldap.password}"
  ldap_host                   = "${data.terraform_remote_state.ldap.host}"
  ldap_port                   = "${data.terraform_remote_state.ldap.port}"
  ldap_role_attr              = "${data.terraform_remote_state.ldap.role_attr}"
  redis_host                  = "${data.terraform_remote_state.pas.redis_host}"
  redis_port                  = "${data.terraform_remote_state.pas.redis_port}"
  redis_ca_cert_file          = "${var.redis_ca_cert_file}"
  redis_password              = "${data.terraform_remote_state.pas.redis_password}"

  pivnet_api_token          = "${var.pivnet_api_token}"
  product_blobs_s3_bucket   = "${var.product_blobs_s3_bucket}"
  product_blobs_s3_endpoint = "${var.product_blobs_s3_endpoint}"
  product_blobs_s3_region   = "${var.product_blobs_s3_region}"
  portal_product_version    = "${var.portal_product_version}"
  s3_access_key_id          = "${var.s3_access_key_id}"
  s3_secret_access_key      = "${var.s3_secret_access_key}"
  s3_auth_type              = "${var.s3_auth_type}"
}

locals {
  vpc_id      = "${data.terraform_remote_state.paperwork.pas_vpc_id}"
  om_key_name = "${var.env_name}-om"
}
