locals {
  pas_subnet_cidr     = "${var.pas_subnet_cidrs[0]}"
  pas_file_glob       = "cf*.pivotal"
  pas_product_slug    = "elastic-runtime"
  pas_product_version = "2.4.13"
  pas_vpc_dns_subnet  = "${var.pas_vpc_dns}/32"

  cf_tools_file_glob    = "pws-dark-cf-tools*"
  cf_tools_product_slug = "pws-dark-cf-tools-tile"

  portal_file_glob    = "pws-dark-portal*"
  portal_product_slug = "pws-dark-portal-tile"

  runtime_config_file_glob    = "pws-dark-runtime-config*.pivotal"
  runtime_config_product_slug = "pws-dark-runtime-config-tile"

  healthwatch_file_glob       = "p-healthwatch*.pivotal"
  healthwatch_product_slug    = "p-healthwatch"
  healthwatch_product_version = "1.6.1"

  compliance_scanner_file_glob       = "p-compliance-scanner*.pivotal"
  compliance_scanner_product_slug    = "p-compliance-scanner"
  compliance_scanner_product_version = "1.0.0"

  pcf_metrics_file_glob       = "apm*.pivotal"
  pcf_metrics_product_slug    = "apm"
  pcf_metrics_product_version = "1.6.1"

  splunk_file_glob       = "splunk-nozzle*.pivotal"
  splunk_product_slug    = "splunk-nozzle"
  splunk_product_version = "1.1.1"
}

data "template_file" "pas_vpc_azs" {
  count = "${length(var.pas_subnet_availability_zones)}"

  template = <<EOF
- name: $${pas_subnet_availability_zone}
EOF

  vars = {
    pas_subnet_availability_zone = "${var.pas_subnet_availability_zones[count.index]}"
  }
}

data "template_file" "pas_subnets" {
  count = "${length(var.pas_subnet_ids)}"

  template = <<EOF
- iaas_identifier: $${pas_subnet_id}
  cidr: $${pas_subnet_cidr}
  dns: $${pas_vpc_dns}
  gateway: $${pas_subnet_gateway}
  reserved_ip_ranges: $${pas_subnet_reserved_ips}
  availability_zone_names:
  - $${pas_subnet_availability_zone}
EOF

  vars = {
    pas_subnet_id                = "${var.pas_subnet_ids[count.index]}"
    pas_subnet_availability_zone = "${var.pas_subnet_availability_zones[count.index]}"
    pas_subnet_cidr              = "${var.pas_subnet_cidrs[count.index]}"
    pas_subnet_reserved_ips      = "${cidrhost(var.pas_subnet_cidrs[count.index], 1)}-${cidrhost(var.pas_subnet_cidrs[count.index], 4)}"
    pas_subnet_gateway           = "${var.pas_subnet_gateways[count.index]}"
    pas_vpc_dns                  = "${var.pas_vpc_dns}"
  }
}

data "template_file" "infrastructure_subnets" {
  count = "${length(var.infrastructure_subnet_ids)}"

  template = <<EOF
    - iaas_identifier: $${infrastructure_subnet_id}
      cidr: $${infrastructure_subnet_cidr}
      dns: $${pas_vpc_dns}
      gateway: $${infrastructure_subnet_gateway}
      reserved_ip_ranges: $${infrastructure_subnet_reserved_ips}
      availability_zone_names:
      - $${infrastructure_subnet_availability_zone}
EOF

  vars = {
    infrastructure_subnet_id                = "${var.infrastructure_subnet_ids[count.index]}"
    infrastructure_subnet_availability_zone = "${var.infrastructure_subnet_availability_zones[count.index]}"
    infrastructure_subnet_cidr              = "${var.infrastructure_subnet_cidrs[count.index]}"
    infrastructure_subnet_reserved_ips      = "${cidrhost(var.infrastructure_subnet_cidrs[count.index], 1)}-${cidrhost(var.infrastructure_subnet_cidrs[count.index], 4)}"
    infrastructure_subnet_gateway           = "${var.infrastructure_subnet_gateways[count.index]}"
    pas_vpc_dns                             = "${var.pas_vpc_dns}"
  }
}

data "template_file" "director_template" {
  template = "${file("${path.module}/director_template.tpl")}"

  vars = {
    ec2_endpoint = "${var.ec2_endpoint}"
    elb_endpoint = "${var.elb_endpoint}"

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
    iaas_configuration_endpoints_ca_cert        = "${var.iaas_configuration_endpoints_ca_cert}"
    iaas_configuration_iam_instance_profile     = "${var.iaas_configuration_iam_instance_profile}"
    iaas_configuration_ssh_key_pair_name        = "${var.ops_manager_ssh_public_key_name}"
    iaas_configuration_region                   = "${var.region}"
    iaas_configuration_security_group           = "${var.vms_security_group_id}"
    iaas_configuration_ssh_private_key          = "${var.ops_manager_ssh_private_key}"
    security_configuration_trusted_certificates = "${var.security_configuration_trusted_certificates}"
    blobstore_instance_profile                  = "${var.blobstore_instance_profile}"

    singleton_availability_zone = "${var.pas_subnet_availability_zones[0]}"
    infrastructure_subnets      = "${join("", data.template_file.infrastructure_subnets.*.rendered)}"
    pas_subnets                 = "${indent(4, join("", data.template_file.pas_subnets.*.rendered))}"
    pas_vpc_azs                 = "${indent(2, join("", data.template_file.pas_vpc_azs.*.rendered))}"

    splunk_syslog_host = "${var.splunk_syslog_host}"
    splunk_syslog_port = "${var.splunk_syslog_port}"
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
    system_domain                       = "${var.system_domain}"
    apps_domain                         = "${var.apps_domain}"

    rds_address  = "${var.rds_address}"
    rds_password = "${var.rds_password}"
    rds_port     = "${var.rds_port}"
    rds_username = "${var.rds_username}"
    rds_ca_cert  = "${var.rds_ca_cert_pem}"

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
    router_cert_pem                                      = "${var.router_cert_pem}"
    router_private_key_pem                               = "${var.router_private_key_pem}"
    router_trusted_ca_certificates                       = "${var.router_trusted_ca_certificates}"
    smtp_host                                            = "${var.smtp_host}"
    smtp_user                                            = "${var.smtp_user}"
    smtp_password                                        = "${var.smtp_password}"
    smtp_tls                                             = "${var.smtp_tls}"
    smtp_from                                            = "${var.smtp_from}"
    smtp_port                                            = "${var.smtp_port}"
    uaa_service_provider_key_credentials_cert_pem        = "${var.uaa_service_provider_key_credentials_cert_pem}"
    uaa_service_provider_key_credentials_private_key_pem = "${var.uaa_service_provider_key_credentials_private_key_pem}"
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
    apps_manager_tools_url                               = "${var.apps_manager_tools_url}"

    kms_key_id            = "${var.kms_key_id}"
    pas_buildpacks_bucket = "${var.pas_buildpacks_bucket}"
    pas_droplets_bucket   = "${var.pas_droplets_bucket}"
    pas_packages_bucket   = "${var.pas_packages_bucket}"
    pas_resources_bucket  = "${var.pas_resources_bucket}"

    pas_vpc_azs                 = "${indent(4, join("", data.template_file.pas_vpc_azs.*.rendered))}"
    singleton_availability_zone = "${var.singleton_availability_zone}"

    splunk_syslog_host = "${var.splunk_syslog_host}"
    splunk_syslog_port = "${var.splunk_syslog_port}"

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
  }
}

data "template_file" "cf_tools_template" {
  template = "${file("${path.module}/cf_tools_template.tpl")}"

  vars = {
    pas_vpc_azs                 = "${indent(4, join("", data.template_file.pas_vpc_azs.*.rendered))}"
    singleton_availability_zone = "${var.singleton_availability_zone}"
  }
}

data "template_file" "portal_template" {
  template = "${file("${path.module}/portal_template.tpl")}"

  vars = {
    jwt_expiration         = "${var.jwt_expiration}"
    ldap_tls_ca_cert       = "${var.ldap_tls_ca_cert}"
    ldap_tls_client_cert   = "${var.ldap_tls_client_cert}"
    ldap_tls_client_key    = "${var.ldap_tls_client_key}"
    smoke_test_client_cert = "${var.smoke_test_client_cert}"
    smoke_test_client_key  = "${var.smoke_test_client_key}"
    ldap_basedn            = "${var.ldap_basedn}"
    ldap_dn                = "${var.ldap_dn}"
    ldap_password          = "${var.ldap_password}"
    ldap_host              = "${var.ldap_host}"
    ldap_port              = "${var.ldap_port}"
    ldap_role_attr         = "${var.ldap_role_attr}"

    mysql_host     = "${var.rds_address}"
    mysql_port     = "${var.rds_port}"
    mysql_db_name  = "portal"
    mysql_username = "${var.rds_username}"
    mysql_password = "${var.rds_password}"
    mysql_ca_cert  = "${var.rds_ca_cert_pem}"

    pas_vpc_azs                 = "${indent(4, join("", data.template_file.pas_vpc_azs.*.rendered))}"
    singleton_availability_zone = "${var.singleton_availability_zone}"
  }
}

data "template_file" "runtime_config_template" {
  template = "${file("${path.module}/runtime_config_template.tpl")}"

  vars = {
    ipsec_log_level       = "${var.ipsec_log_level}"
    ipsec_optional        = "${var.ipsec_optional}"
    ipsec_subnet_cidrs    = "${join(",",  var.ipsec_subnet_cidrs)}"
    no_ipsec_subnet_cidrs = "${join(",", concat(var.no_ipsec_subnet_cidrs, list(local.pas_vpc_dns_subnet)))}"
    ssh_banner            = "${file(var.custom_ssh_banner_file)}"
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

data "template_file" "download_pas_config" {
  template = "${file("${path.module}/download_product_config.tpl")}"

  vars = {
    pivnet_file_glob    = "${local.pas_file_glob}"
    pivnet_product_slug = "${local.pas_product_slug}"
    product_version     = "${local.pas_product_version}"

    pivnet_api_token = "${var.pivnet_api_token}"
    s3_bucket        = "${var.product_blobs_s3_bucket}"

    s3_endpoint          = "${var.product_blobs_s3_endpoint}"
    s3_region_name       = "${var.product_blobs_s3_region}"
    s3_access_key_id     = "${var.s3_access_key_id}"
    s3_secret_access_key = "${var.s3_secret_access_key}"
    s3_auth_type         = "${var.s3_auth_type}"
  }
}

data "template_file" "download_splunk_config" {
  template = "${file("${path.module}/download_product_config.tpl")}"

  vars = {
    pivnet_file_glob    = "${local.splunk_file_glob}"
    pivnet_product_slug = "${local.splunk_product_slug}"
    product_version     = "${local.splunk_product_version}"

    pivnet_api_token = "${var.pivnet_api_token}"
    s3_bucket        = "${var.product_blobs_s3_bucket}"

    s3_endpoint          = "${var.product_blobs_s3_endpoint}"
    s3_region_name       = "${var.product_blobs_s3_region}"
    s3_access_key_id     = "${var.s3_access_key_id}"
    s3_secret_access_key = "${var.s3_secret_access_key}"
    s3_auth_type         = "${var.s3_auth_type}"
  }
}

data "template_file" "download_cf_tools_config" {
  template = "${file("${path.module}/download_product_config.tpl")}"

  vars = {
    pivnet_file_glob    = "${local.cf_tools_file_glob}"
    pivnet_product_slug = "${local.cf_tools_product_slug}"
    product_version     = "${var.cf_tools_product_version}"

    pivnet_api_token = "${var.pivnet_api_token}"
    s3_bucket        = "${var.product_blobs_s3_bucket}"

    s3_endpoint          = "${var.product_blobs_s3_endpoint}"
    s3_region_name       = "${var.product_blobs_s3_region}"
    s3_access_key_id     = "${var.s3_access_key_id}"
    s3_secret_access_key = "${var.s3_secret_access_key}"
    s3_auth_type         = "${var.s3_auth_type}"
  }
}

data "template_file" "download_runtime_config_config" {
  template = "${file("${path.module}/download_product_config.tpl")}"

  vars = {
    pivnet_file_glob    = "${local.runtime_config_file_glob}"
    pivnet_product_slug = "${local.runtime_config_product_slug}"
    product_version     = "${var.runtime_config_product_version}"

    pivnet_api_token = "${var.pivnet_api_token}"
    s3_bucket        = "${var.product_blobs_s3_bucket}"

    s3_endpoint          = "${var.product_blobs_s3_endpoint}"
    s3_region_name       = "${var.product_blobs_s3_region}"
    s3_access_key_id     = "${var.s3_access_key_id}"
    s3_secret_access_key = "${var.s3_secret_access_key}"
    s3_auth_type         = "${var.s3_auth_type}"
  }
}

data "template_file" "download_portal_config" {
  template = "${file("${path.module}/download_product_config.tpl")}"

  vars = {
    pivnet_file_glob    = "${local.portal_file_glob}"
    pivnet_product_slug = "${local.portal_product_slug}"
    product_version     = "${var.portal_product_version}"

    pivnet_api_token = "${var.pivnet_api_token}"
    s3_bucket        = "${var.product_blobs_s3_bucket}"

    s3_endpoint          = "${var.product_blobs_s3_endpoint}"
    s3_region_name       = "${var.product_blobs_s3_region}"
    s3_access_key_id     = "${var.s3_access_key_id}"
    s3_secret_access_key = "${var.s3_secret_access_key}"
    s3_auth_type         = "${var.s3_auth_type}"
  }
}

data "template_file" "download_healthwatch_config" {
  template = "${file("${path.module}/download_product_config.tpl")}"

  vars = {
    pivnet_file_glob    = "${local.healthwatch_file_glob}"
    pivnet_product_slug = "${local.healthwatch_product_slug}"
    product_version     = "${local.healthwatch_product_version}"

    pivnet_api_token = "${var.pivnet_api_token}"
    s3_bucket        = "${var.product_blobs_s3_bucket}"

    s3_endpoint          = "${var.product_blobs_s3_endpoint}"
    s3_region_name       = "${var.product_blobs_s3_region}"
    s3_access_key_id     = "${var.s3_access_key_id}"
    s3_secret_access_key = "${var.s3_secret_access_key}"
    s3_auth_type         = "${var.s3_auth_type}"
  }
}

data "template_file" "download_compliance_scanner_config" {
  template = "${file("${path.module}/download_product_config.tpl")}"

  vars = {
    pivnet_file_glob    = "${local.compliance_scanner_file_glob}"
    pivnet_product_slug = "${local.compliance_scanner_product_slug}"
    product_version     = "${local.compliance_scanner_product_version}"

    pivnet_api_token = "${var.pivnet_api_token}"
    s3_bucket        = "${var.product_blobs_s3_bucket}"

    s3_endpoint          = "${var.product_blobs_s3_endpoint}"
    s3_region_name       = "${var.product_blobs_s3_region}"
    s3_access_key_id     = "${var.s3_access_key_id}"
    s3_secret_access_key = "${var.s3_secret_access_key}"
    s3_auth_type         = "${var.s3_auth_type}"
  }
}

data "template_file" "download_pcf_metrics_config" {
  template = "${file("${path.module}/download_product_config.tpl")}"

  vars = {
    pivnet_file_glob    = "${local.pcf_metrics_file_glob}"
    pivnet_product_slug = "${local.pcf_metrics_product_slug}"
    product_version     = "${local.pcf_metrics_product_version}"

    pivnet_api_token = "${var.pivnet_api_token}"
    s3_bucket        = "${var.product_blobs_s3_bucket}"

    s3_endpoint          = "${var.product_blobs_s3_endpoint}"
    s3_region_name       = "${var.product_blobs_s3_region}"
    s3_access_key_id     = "${var.s3_access_key_id}"
    s3_secret_access_key = "${var.s3_secret_access_key}"
    s3_auth_type         = "${var.s3_auth_type}"
  }
}
