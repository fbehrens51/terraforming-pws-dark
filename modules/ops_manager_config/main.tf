locals {
  pas_subnet_cidr = "${var.pas_subnet_cidrs[0]}"
}

data "aws_vpc" "vpc" {
  id = "${var.vpc_id}"
}

data "template_file" "director_template" {
  template = "${file("${path.module}/director_template.tpl")}"

  vars = {
    ec2_endpoint = "${var.ec2_endpoint}"
    elb_endpoint = "${var.elb_endpoint}"

    availability_zones                          = "[${join(",", var.pas_subnet_availability_zones)}]"
    singleton_availability_zone                 = "${var.singleton_availability_zone}"
    custom_ssh_banner                           = "${file(var.custom_ssh_banner_file)}"
    rds_database                                = "director"
    rds_address                                 = "${var.rds_address}"
    rds_port                                    = "${var.rds_port}"
    rds_username                                = "${var.rds_username}"
    rds_password                                = "${var.rds_password}"
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
    iaas_configuration_endpoints_ca_cert        = "${file(var.iaas_configuration_endpoints_ca_cert)}"
    iaas_configuration_iam_instance_profile     = "${var.iaas_configuration_iam_instance_profile}"
    iaas_configuration_ssh_key_pair_name        = "${var.ops_manager_ssh_public_key_name}"
    iaas_configuration_region                   = "${var.region}"
    iaas_configuration_security_group           = "${var.vms_security_group_id}"
    iaas_configuration_ssh_private_key          = "${var.ops_manager_ssh_private_key}"
    security_configuration_trusted_certificates = "${file(var.security_configuration_trusted_certificates)}"
    blobstore_instance_profile                  = "${var.blobstore_instance_profile}"

    pas_subnet_subnet_id         = "${var.pas_subnet_ids[0]}"
    pas_subnet_availability_zone = "${var.pas_subnet_availability_zones[0]}"
    pas_subnet_cidr              = "${var.pas_subnet_cidrs[0]}"
    pas_subnet_reserved_ips      = "${cidrhost(var.pas_subnet_cidrs[0], 1)}-${cidrhost(var.pas_subnet_cidrs[0], 4)}"
    pas_subnet_gateway           = "${var.pas_subnet_gateways[0]}"
    pas_subnet_dns               = "${cidrhost(data.aws_vpc.vpc.cidr_block, 2)}"
  }
}

data "template_file" "cf_template" {
  template = "${file("${path.module}/cf_template.tpl")}"

  vars = {
    region                              = "${var.region}"
    s3_endpoint                         = "https://${var.s3_endpoint}"
    router_elb_names                    = "[${join(",", var.router_elb_names)}]"
    errands_deploy_autoscaler           = "${var.errands_deploy_autoscaler}"
    errands_deploy_notifications        = "${var.errands_deploy_notifications}"
    errands_deploy_notifications_ui     = "${var.errands_deploy_notifications_ui}"
    errands_metric_registrar_smoke_test = "${var.errands_metric_registrar_smoke_test}"
    errands_nfsbrokerpush               = "${var.errands_nfsbrokerpush}"
    errands_push_apps_manager           = "${var.errands_push_apps_manager}"
    errands_push_usage_service          = "${var.errands_push_usage_service}"
    errands_smbbrokerpush               = "${var.errands_smbbrokerpush}"
    errands_smoke_tests                 = "${var.errands_smoke_tests}"
    errands_test_autoscaling            = "${var.errands_test_autoscaling}"
    singleton_availability_zone         = "${var.singleton_availability_zone}"
    system_domain                       = "${var.system_domain}"
    apps_domain                         = "${var.apps_domain}"

    rds_address  = "${var.rds_address}"
    rds_password = "${var.rds_password}"
    rds_port     = "${var.rds_port}"
    rds_username = "${var.rds_username}"
    rds_ca_cert  = "${file(var.rds_ca_cert_file)}"

    password_policies_max_retry            = "${var.password_policies_max_retry}"
    password_policies_expires_after_months = "${var.password_policies_expires_after_months}"
    password_policies_max_retry            = "${var.password_policies_max_retry}"
    password_policies_min_length           = "${var.password_policies_min_length}"
    password_policies_min_lowercase        = "${var.password_policies_min_lowercase}"
    password_policies_min_numeric          = "${var.password_policies_min_numeric}"
    password_policies_min_special          = "${var.password_policies_min_special}"
    password_policies_min_uppercase        = "${var.password_policies_min_uppercase}"

    cloud_controller_encrypt_key_secret                  = "${var.cloud_controller_encrypt_key_secret}"
    credhub_encryption_password                          = "${var.credhub_encryption_password}"
    router_cert_pem                                      = "${file(var.router_cert_pem_file)}"
    router_private_key_pem                               = "${file(var.router_private_key_pem_file)}"
    router_trusted_ca_certificates                       = "${file(var.router_trusted_ca_certificates_file)}"
    smtp_host                                            = "${var.smtp_host}"
    smtp_user                                            = "${var.smtp_user}"
    smtp_password                                        = "${var.smtp_password}"
    smtp_tls                                             = "${var.smtp_tls}"
    smtp_from                                            = "${var.smtp_from}"
    smtp_port                                            = "${var.smtp_port}"
    uaa_service_provider_key_credentials_cert_pem        = "${file(var.uaa_service_provider_key_credentials_cert_pem_file)}"
    uaa_service_provider_key_credentials_private_key_pem = "${file(var.uaa_service_provider_key_credentials_private_key_pem_file)}"
    apps_manager_global_wrapper_footer_content           = "${var.apps_manager_global_wrapper_footer_content}"
    apps_manager_global_wrapper_header_content           = "${var.apps_manager_global_wrapper_header_content}"
    apps_manager_footer_text                             = "${var.apps_manager_footer_text}"
    apps_manager_accent_color                            = "${var.apps_manager_accent_color}"
    apps_manager_global_wrapper_text_color               = "${var.apps_manager_global_wrapper_text_color}"
    apps_manager_company_name                            = "${var.apps_manager_company_name}"
    apps_manager_global_wrapper_bg_color                 = "${var.apps_manager_global_wrapper_bg_color}"
    apps_manager_favicon                                 = "${base64encode(file(var.apps_manager_favicon_file))}"
    apps_manager_square_logo                             = "${base64encode(file(var.apps_manager_square_logo_file))}"
    apps_manager_main_logo                               = "${base64encode(file(var.apps_manager_main_logo_file))}"

    pas_buildpacks_bucket = "${var.pas_buildpacks_bucket}"
    pas_droplets_bucket   = "${var.pas_droplets_bucket}"
    pas_packages_bucket   = "${var.pas_packages_bucket}"
    pas_resources_bucket  = "${var.pas_resources_bucket}"
  }
}

data "template_file" "portal_template" {
  template = "${file("${path.module}/portal_template.tpl")}"

  vars = {
    jwt_expiration       = "${var.jwt_expiration}"
    ldap_tls_ca_cert     = "${file(var.ldap_tls_ca_cert_file)}"
    ldap_tls_client_cert = "${file(var.ldap_tls_client_cert_file)}"
    ldap_tls_client_key  = "${file(var.ldap_tls_client_key_file)}"
    ldap_basedn          = "${var.ldap_basedn}"
    ldap_dn              = "${var.ldap_dn}"
    ldap_password        = "${var.ldap_password}"
    ldap_host            = "${var.ldap_host}"
    ldap_port            = "${var.ldap_port}"
    ldap_role_attr       = "${var.ldap_role_attr}"
    redis_host           = "${var.redis_host}"
    redis_port           = "${var.redis_port}"
    redis_ca_cert        = "${file(var.redis_ca_cert_file)}"
    redis_password       = "${var.redis_password}"
  }
}

data "template_file" "create_db" {
  template = "${file("${path.module}/create_db.tpl")}"

  vars = {
    rds_address  = "${var.rds_address}"
    rds_password = "${var.rds_password}"
    rds_username = "${var.rds_username}"
  }
}

data "template_file" "drop_db" {
  template = "${file("${path.module}/drop_db.tpl")}"

  vars = {
    rds_address  = "${var.rds_address}"
    rds_password = "${var.rds_password}"
    rds_username = "${var.rds_username}"
  }
}
