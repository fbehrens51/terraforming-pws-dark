locals {
  concourse_file_glob       = "*.pivotal"
  concourse_product_slug    = "pws-dark-concourse-tile"
  concourse_product_version = "${var.concourse_version}"

  compliance_scanner_file_glob       = "p-compliance-scanner*.pivotal"
  compliance_scanner_product_slug    = "p-compliance-scanner"
  compliance_scanner_product_version = "1.1.19"
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

    concourse_worker_role_name = "${var.concourse_worker_role_name}"

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

data "template_file" "create_db" {
  template = "${file("${path.module}/create_db.tpl")}"

  vars = {
    postgres_host     = "${var.postgres_host}"
    postgres_port     = "${var.postgres_port}"
    postgres_username = "${var.postgres_username}"
    postgres_password = "${var.postgres_password}"
  }
}

resource "random_string" "user_passwords" {
  count = "${length(var.concourse_users)}"

  length = "16"
}

data "template_file" "users_to_add" {
  count = "${length(var.concourse_users)}"

  template = <<EOF
- username: ${var.concourse_users[count.index]}
  password:
    secret: ${bcrypt(element(random_string.user_passwords.*.result, count.index), 15)}
EOF
}

data "template_file" "concourse_template" {
  template = "${file("${path.module}/concourse_template.tpl")}"

  vars = {
    singleton_availability_zone = "${var.singleton_availability_zone}"
    control_plane_vpc_azs       = "${indent(4, join("", data.template_file.control_plane_vpc_azs.*.rendered))}"

    web_elb_names = "[${join(",", var.web_elb_names)}]"

    plane_endpoint = "${module.domains.control_plane_plane_fqdn}"

    concourse_cert_pem        = "${var.concourse_cert_pem}"
    concourse_private_key_pem = "${var.concourse_private_key_pem}"

    splunk_syslog_host    = "${var.splunk_syslog_host}"
    splunk_syslog_port    = "${var.splunk_syslog_port}"
    splunk_syslog_ca_cert = "${var.splunk_syslog_ca_cert}"

    postgres_host     = "${var.postgres_host}"
    postgres_port     = "${var.postgres_port}"
    postgres_db_name  = "${var.postgres_db_name}"
    postgres_username = "${var.postgres_username}"
    postgres_password = "${var.postgres_password}"
    postgres_ca_cert  = "${var.postgres_ca_cert}"
    users_to_add      = "${join("", data.template_file.users_to_add.*.rendered)}"
  }
}

data "template_file" "download_compliance_scanner_config" {
  template = "${file("${path.module}/download_product_config.tpl")}"

  vars = {
    pivnet_file_glob    = "${local.compliance_scanner_file_glob}"
    pivnet_product_slug = "${local.compliance_scanner_product_slug}"
    product_version     = "${local.compliance_scanner_product_version}"

    pivnet_api_token = "${var.pivnet_api_token}"
    s3_bucket        = "${var.mirror_bucket_name}"

    s3_endpoint          = "${var.s3_endpoint}"
    s3_region_name       = "${var.region}"
    s3_access_key_id     = "${var.s3_access_key_id}"
    s3_secret_access_key = "${var.s3_secret_access_key}"
    s3_auth_type         = "${var.s3_auth_type}"
  }
}

data "template_file" "download_concourse_config" {
  template = "${file("${path.module}/download_product_config.tpl")}"

  vars = {
    pivnet_file_glob    = "${local.concourse_file_glob}"
    pivnet_product_slug = "${local.concourse_product_slug}"
    product_version     = "${local.concourse_product_version}"

    pivnet_api_token = "${var.pivnet_api_token}"
    s3_bucket        = "${var.mirror_bucket_name}"

    s3_endpoint          = "${var.s3_endpoint}"
    s3_region_name       = "${var.region}"
    s3_access_key_id     = "${var.s3_access_key_id}"
    s3_secret_access_key = "${var.s3_secret_access_key}"
    s3_auth_type         = "${var.s3_auth_type}"
  }
}
