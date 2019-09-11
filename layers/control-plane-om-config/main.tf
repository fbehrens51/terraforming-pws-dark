terraform {
  backend "s3" {}
}

module "providers" {
  source = "../../modules/dark_providers"
}

data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "paperwork"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

data "terraform_remote_state" "bootstrap_control_plane" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "bootstrap_control_plane"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

data "aws_region" "current" {}

module "om_config" {
  source = "../../modules/control_plane_ops_manager_config"

  control_plane_subnet_ids                = "${data.terraform_remote_state.bootstrap_control_plane.control_plane_subnet_ids}"
  vms_security_group_id                   = "${data.terraform_remote_state.bootstrap_control_plane.vms_security_group_id}"
  control_plane_subnet_availability_zones = "${data.terraform_remote_state.bootstrap_control_plane.control_plane_subnet_availability_zones}"
  control_plane_subnet_gateways           = "${data.terraform_remote_state.bootstrap_control_plane.control_plane_subnet_gateways}"
  control_plane_subnet_cidrs              = "${data.terraform_remote_state.bootstrap_control_plane.control_plane_subnet_cidrs}"
  control_plane_vpc_dns                   = "${data.terraform_remote_state.paperwork.control_plane_vpc_dns}"

  vpc_id       = "${local.vpc_id}"
  env_name     = "${var.env_name}"
  region       = "${data.aws_region.current.name}"
  s3_endpoint  = "${var.s3_endpoint}"
  ec2_endpoint = "${var.ec2_endpoint}"
  elb_endpoint = "${var.elb_endpoint}"

  singleton_availability_zone = "${var.singleton_availability_zone}"

  concourse_cert_pem        = "${data.terraform_remote_state.paperwork.concourse_server_cert}"
  concourse_private_key_pem = "${data.terraform_remote_state.paperwork.concourse_server_key}"
  trusted_ca_certs          = "${data.terraform_remote_state.paperwork.trusted_ca_certs}"

  concourse_domain = "${data.terraform_remote_state.paperwork.control_plane_domain}"

  web_elb_names = ["${data.terraform_remote_state.bootstrap_control_plane.web_elb_id}"]

  uaa_elb_names = ["${data.terraform_remote_state.bootstrap_control_plane.uaa_elb_id}"]

  credhub_elb_names = ["${data.terraform_remote_state.bootstrap_control_plane.credhub_elb_id}"]

  smtp_host       = "${var.smtp_host}"
  smtp_user       = "${var.smtp_user}"
  smtp_password   = "${var.smtp_password}"
  smtp_tls        = "${var.smtp_tls}"
  smtp_from       = "${var.smtp_from}"
  smtp_port       = "${var.smtp_port}"
  smtp_recipients = "${var.smtp_recipients}"
  smtp_domain     = "${var.smtp_domain}"
  smtp_enabled    = "${var.smtp_enabled}"

  platform_automation_engine_worker_role_name = "${data.terraform_remote_state.paperwork.platform_automation_engine_worker_role_name}"

  iaas_configuration_endpoints_ca_cert    = "${var.iaas_configuration_endpoints_ca_cert}"
  iaas_configuration_iam_instance_profile = "${data.terraform_remote_state.paperwork.director_role_name}"

  ntp_servers                                 = "${var.ntp_servers}"
  custom_ssh_banner_file                      = "${var.custom_ssh_banner_file}"
  security_configuration_trusted_certificates = "${data.terraform_remote_state.paperwork.trusted_ca_certs}"

  # director_rds_address  = "${data.terraform_remote_state.bootstrap_control_plane.director_rds_address}"
  # director_rds_password = "${data.terraform_remote_state.bootstrap_control_plane.director_rds_password}"
  # director_rds_port     = "${data.terraform_remote_state.bootstrap_control_plane.director_rds_port}"
  # director_rds_username = "${data.terraform_remote_state.bootstrap_control_plane.director_rds_username}"


  # rds_ca_cert_pem = "${data.terraform_remote_state.paperwork.rds_ca_cert_pem}"

  ops_manager_ssh_public_key_name = "${local.om_key_name}"
  ops_manager_ssh_private_key     = "${data.terraform_remote_state.bootstrap_control_plane.om_private_key_pem}"

  # Used by the download config

  pivnet_api_token                         = "${var.pivnet_api_token}"
  product_blobs_s3_bucket                  = "${var.product_blobs_s3_bucket}"
  product_blobs_s3_endpoint                = "${var.product_blobs_s3_endpoint}"
  product_blobs_s3_region                  = "${var.product_blobs_s3_region}"
  s3_access_key_id                         = "${var.s3_access_key_id}"
  s3_secret_access_key                     = "${var.s3_secret_access_key}"
  s3_auth_type                             = "${var.s3_auth_type}"
  pws_dark_iam_s3_resource_product_version = "${var.pws_dark_iam_s3_resource_product_version}"
}

locals {
  vpc_id      = "${data.terraform_remote_state.paperwork.pas_vpc_id}"
  om_key_name = "${var.env_name}-om"
}
