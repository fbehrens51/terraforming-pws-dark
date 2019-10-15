locals {
  platform_automation_engine_file_glob       = "*.pivotal"
  platform_automation_engine_product_slug    = "platform-automation-engine"
  platform_automation_engine_product_version = "1.0.3-beta.1"

  pws_dark_iam_s3_resource_file_glob    = "pws-dark-iam-s3-resource-tile*.pivotal"
  pws_dark_iam_s3_resource_product_slug = "pws-dark-iam-s3-resource-tile"
}

data "aws_vpc" "vpc" {
  id = "${var.vpc_id}"
}

data "template_file" "control_plane_vpc_azs" {
  count = "${length(var.control_plane_subnet_availability_zones)}"

  template = <<EOF
- name: $${control_plane_subnet_availability_zone}
EOF

  vars = {
    control_plane_subnet_availability_zone = "${var.control_plane_subnet_availability_zones[count.index]}"
  }
}

data "template_file" "control_plane_subnets" {
  count = "${length(var.control_plane_subnet_ids)}"

  template = <<EOF
    - iaas_identifier: $${control_plane_subnet_id}
      cidr: $${control_plane_subnet_cidr}
      dns: $${control_plane_vpc_dns}
      gateway: $${control_plane_subnet_gateway}
      reserved_ip_ranges: $${control_plane_subnet_reserved_ips}
      availability_zone_names:
      - $${control_plane_subnet_availability_zone}
EOF

  vars = {
    control_plane_subnet_id                = "${var.control_plane_subnet_ids[count.index]}"
    control_plane_subnet_availability_zone = "${var.control_plane_subnet_availability_zones[count.index]}"
    control_plane_subnet_cidr              = "${var.control_plane_subnet_cidrs[count.index]}"
    control_plane_subnet_reserved_ips      = "${cidrhost(var.control_plane_subnet_cidrs[count.index], 1)}-${cidrhost(var.control_plane_subnet_cidrs[count.index], 4)}"
    control_plane_subnet_gateway           = "${var.control_plane_subnet_gateways[count.index]}"
    control_plane_vpc_dns                  = "${var.control_plane_vpc_dns}"
  }
}

data "template_file" "director_template" {
  template = "${file("${path.module}/director_template.tpl")}"

  vars = {
    ec2_endpoint = "${var.ec2_endpoint}"
    elb_endpoint = "${var.elb_endpoint}"

    singleton_availability_zone                 = "${var.singleton_availability_zone}"
    custom_ssh_banner                           = "${var.custom_ssh_banner}"
    smtp_domain                                 = "${var.smtp_domain}"
    smtp_enabled                                = "${var.smtp_enabled}"
    smtp_from                                   = "${var.smtp_from}"
    smtp_host                                   = "${var.smtp_host}"
    smtp_port                                   = "${var.smtp_port}"
    smtp_recipients                             = "${var.smtp_recipients}"
    smtp_user                                   = "${var.smtp_user}"
    smtp_password                               = "${var.smtp_password}"
    smtp_tls                                    = "${var.smtp_tls}"
    env_name                                    = "${var.env_name}"
    ntp_servers                                 = "${join(",", var.ntp_servers)}"
    iaas_configuration_endpoints_ca_cert        = "${var.iaas_configuration_endpoints_ca_cert}"
    iaas_configuration_iam_instance_profile     = "${var.iaas_configuration_iam_instance_profile}"
    iaas_configuration_ssh_key_pair_name        = "${var.ops_manager_ssh_public_key_name}"
    iaas_configuration_region                   = "${var.region}"
    iaas_configuration_security_group           = "${var.vms_security_group_id}"
    iaas_configuration_ssh_private_key          = "${var.ops_manager_ssh_private_key}"
    security_configuration_trusted_certificates = "${var.security_configuration_trusted_certificates}"

    kms_key_arn = "${var.volume_encryption_kms_key_arn}"

    platform_automation_engine_worker_role_name = "${var.platform_automation_engine_worker_role_name}"

    control_plane_subnets = "${indent(4, join("", data.template_file.control_plane_subnets.*.rendered))}"
    control_plane_vpc_azs = "${indent(2, join("", data.template_file.control_plane_vpc_azs.*.rendered))}"

    splunk_syslog_host    = "${var.splunk_syslog_host}"
    splunk_syslog_port    = "${var.splunk_syslog_port}"
    splunk_syslog_ca_cert = "${var.splunk_syslog_ca_cert}"
  }
}

module "domains" {
  source = "../domains"

  root_domain = "${var.root_domain}"
}

data "template_file" "platform_automation_engine_template" {
  template = "${file("${path.module}/platform_automation_engine_template.tpl")}"

  vars = {
    singleton_availability_zone = "${var.singleton_availability_zone}"
    control_plane_vpc_azs       = "${indent(4, join("", data.template_file.control_plane_vpc_azs.*.rendered))}"

    uaa_elb_names     = "[${join(",", var.uaa_elb_names)}]"
    credhub_elb_names = "[${join(",", var.credhub_elb_names)}]"
    web_elb_names     = "[${join(",", var.web_elb_names)}]"

    uaa_endpoint     = "${module.domains.control_plane_uaa_fqdn}"
    credhub_endpoint = "${module.domains.control_plane_credhub_fqdn}"
    plane_endpoint   = "${module.domains.control_plane_plane_fqdn}"

    concourse_cert_pem        = "${var.concourse_cert_pem}"
    concourse_private_key_pem = "${var.concourse_private_key_pem}"
    trusted_ca_certs          = "${var.trusted_ca_certs}"

    splunk_syslog_host    = "${var.splunk_syslog_host}"
    splunk_syslog_port    = "${var.splunk_syslog_port}"
    splunk_syslog_ca_cert = "${var.splunk_syslog_ca_cert}"
  }
}

data "template_file" "download_pws_dark_iam_s3_resource_config" {
  template = "${file("${path.module}/download_product_config.tpl")}"

  vars = {
    pivnet_file_glob    = "${local.pws_dark_iam_s3_resource_file_glob}"
    pivnet_product_slug = "${local.pws_dark_iam_s3_resource_product_slug}"
    product_version     = "${var.pws_dark_iam_s3_resource_product_version}"

    pivnet_api_token = "${var.pivnet_api_token}"
    s3_bucket        = "${var.product_blobs_s3_bucket}"

    s3_endpoint          = "${var.product_blobs_s3_endpoint}"
    s3_region_name       = "${var.product_blobs_s3_region}"
    s3_access_key_id     = "${var.s3_access_key_id}"
    s3_secret_access_key = "${var.s3_secret_access_key}"
    s3_auth_type         = "${var.s3_auth_type}"
  }
}

data "template_file" "download_platform_automation_engine_config" {
  template = "${file("${path.module}/download_product_config.tpl")}"

  vars = {
    pivnet_file_glob    = "${local.platform_automation_engine_file_glob}"
    pivnet_product_slug = "${local.platform_automation_engine_product_slug}"
    product_version     = "${local.platform_automation_engine_product_version}"

    pivnet_api_token = "${var.pivnet_api_token}"
    s3_bucket        = "${var.product_blobs_s3_bucket}"

    s3_endpoint          = "${var.product_blobs_s3_endpoint}"
    s3_region_name       = "${var.product_blobs_s3_region}"
    s3_access_key_id     = "${var.s3_access_key_id}"
    s3_secret_access_key = "${var.s3_secret_access_key}"
    s3_auth_type         = "${var.s3_auth_type}"
  }
}
