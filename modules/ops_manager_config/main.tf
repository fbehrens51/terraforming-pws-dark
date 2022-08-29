locals {
  pas_subnet_cidr = var.pas_subnet_cidrs[0]
  om_syslog_conf = yamlencode({
    "syslog-settings" : {
      "enabled" : true,
      "address" : var.syslog_host,
      "port" : var.syslog_port,
      "transport_protocol" : "tcp",
      "tls_enabled" : true,
      "ssl_ca_certificate" : var.syslog_ca_cert,
      "permitted_peer" : var.syslog_host,
      "queue_size" : null,
      "forward_debug_logs" : false
    }
  })
  om_ssl_conf = yamlencode({
    "ssl-certificate" : {
      "certificate" : var.om_server_cert,
      "private_key" : var.om_server_key
    }
  })
  om_tokens_expiration_conf = yamlencode({
    "tokens-expiration" : {
      "access_token_expiration" : 3600,   # 1 hour
      "refresh_token_expiration" : 82800, # 23 hours
      "session_idle_timeout" : 3600       # 1 hour
    }
  })
  om_ssh_banner_conf = yamlencode({
    "banner-settings" : {
      "ssh_banner_contents" : var.custom_ssh_banner
    }
  })
}

data "template_file" "pas_vpc_azs" {
  count = length(var.pas_subnet_availability_zones)

  template = <<EOF
- name: $${pas_subnet_availability_zone}
EOF

  vars = {
    pas_subnet_availability_zone = var.pas_subnet_availability_zones[count.index]
  }
}

data "template_file" "pas_subnets" {
  count = length(var.pas_subnet_ids)

  template = <<EOF
- availability_zone_names:
  - $${pas_subnet_availability_zone}
  cidr: $${pas_subnet_cidr}
  dns: $${pas_vpc_dns}
  gateway: $${pas_subnet_gateway}
  iaas_identifier: $${pas_subnet_id}
  reserved_ip_ranges: $${pas_subnet_reserved_ips}
EOF

  vars = {
    pas_subnet_id                = var.pas_subnet_ids[count.index]
    pas_subnet_availability_zone = var.pas_subnet_availability_zones[count.index]
    pas_subnet_cidr              = var.pas_subnet_cidrs[count.index]
    pas_subnet_reserved_ips      = "${cidrhost(var.pas_subnet_cidrs[count.index], 1)}-${cidrhost(var.pas_subnet_cidrs[count.index], 4)}"
    pas_subnet_gateway           = var.pas_subnet_gateways[count.index]
    pas_vpc_dns                  = var.pas_vpc_dns
  }
}

data "template_file" "infrastructure_subnets" {
  count = length(var.infrastructure_subnet_ids)

  template = <<EOF
- availability_zone_names:
  - $${infrastructure_subnet_availability_zone}
  cidr: $${infrastructure_subnet_cidr}
  dns: $${pas_vpc_dns}
  gateway: $${infrastructure_subnet_gateway}
  iaas_identifier: $${infrastructure_subnet_id}
  reserved_ip_ranges: $${infrastructure_subnet_reserved_ips}
EOF

  vars = {
    infrastructure_subnet_id                = var.infrastructure_subnet_ids[count.index]
    infrastructure_subnet_availability_zone = var.infrastructure_subnet_availability_zones[count.index]
    infrastructure_subnet_cidr              = var.infrastructure_subnet_cidrs[count.index]
    infrastructure_subnet_reserved_ips      = "${cidrhost(var.infrastructure_subnet_cidrs[count.index], 1)}-${cidrhost(var.infrastructure_subnet_cidrs[count.index], 4)}"
    infrastructure_subnet_gateway           = var.infrastructure_subnet_gateways[count.index]
    pas_vpc_dns                             = var.pas_vpc_dns
  }
}

locals {
  director_template = templatefile("${path.module}/director_template.tpl", {
    scale                                       = var.scale["p-bosh"]
    ec2_endpoint                                = var.ec2_endpoint
    elb_endpoint                                = var.elb_endpoint
    custom_ssh_banner                           = var.custom_ssh_banner
    rds_database                                = "director"
    rds_address                                 = var.rds_address
    rds_port                                    = var.rds_port
    rds_username                                = var.rds_username
    rds_password                                = var.rds_password
    rds_ca_cert                                 = var.rds_ca_cert_pem
    smtp_domain                                 = var.smtp_domain
    smtp_enabled                                = var.smtp_enabled
    smtp_from                                   = var.smtp_from
    smtp_host                                   = var.smtp_host
    smtp_port                                   = var.smtp_port
    smtp_recipients                             = var.smtp_recipients
    smtp_user                                   = var.smtp_user
    smtp_password                               = var.smtp_password
    smtp_tls                                    = var.smtp_tls
    env_name                                    = var.env_name
    ntp_servers                                 = join(",", var.ntp_servers)
    iaas_configuration_endpoints_ca_cert        = var.iaas_configuration_endpoints_ca_cert
    iaas_configuration_iam_instance_profile     = var.iaas_configuration_iam_instance_profile
    iaas_configuration_ssh_key_pair_name        = var.ops_manager_ssh_public_key_name
    iaas_configuration_region                   = var.region
    iaas_configuration_security_group           = var.vms_security_group_id
    iaas_configuration_ssh_private_key          = var.ops_manager_ssh_private_key
    security_configuration_trusted_certificates = var.security_configuration_trusted_certificates
    blobstore_instance_profile                  = var.blobstore_instance_profile
    tsdb_instance_profile                       = var.tsdb_instance_profile
    kms_key_arn                                 = var.volume_encryption_kms_key_arn
    singleton_availability_zone                 = var.pas_subnet_availability_zones[0]
    infrastructure_subnets                      = join("", data.template_file.infrastructure_subnets.*.rendered)
    pas_subnets                                 = join("", data.template_file.pas_subnets.*.rendered)
    pas_vpc_azs                                 = join("", data.template_file.pas_vpc_azs.*.rendered)
    syslog_host                                 = var.syslog_host
    syslog_port                                 = var.syslog_port
    syslog_ca_cert                              = var.syslog_ca_cert
    isolation_segment_to_subnets                = var.isolation_segment_to_subnets
    isolation_segment_to_security_groups        = var.isolation_segment_to_security_groups
    pas_vpc_dns                                 = var.pas_vpc_dns
    director_blobstore_bucket                   = var.director_blobstore_bucket
    director_blobstore_s3_endpoint              = "https://${var.s3_endpoint}"
    director_blobstore_location                 = var.director_blobstore_location // s3 or local
    forwarders                                  = var.forwarders
    extra_users                                 = var.extra_users
    disk_type                                   = var.disk_type
    grafana_lb_security_group_id                = "[${join(",", var.grafana_lb_security_group_id)}]" // vm extension
  })
}

locals {
  cf_template = templatefile("${path.module}/cf_template.tpl", {
    scale                                                = var.scale["cf"]
    region                                               = var.region
    s3_endpoint                                          = "https://${var.s3_endpoint}"
    router_elb_names                                     = "[${join(",", var.router_elb_names)}]"
    errands_deploy_autoscaler                            = var.errands_deploy_autoscaler
    errands_deploy_notifications                         = var.errands_deploy_notifications
    errands_deploy_notifications_ui                      = var.errands_deploy_notifications_ui
    errands_metric_registrar_smoke_test                  = var.errands_metric_registrar_smoke_test
    errands_nfsbrokerpush                                = var.errands_nfsbrokerpush
    errands_push_apps_manager                            = var.errands_push_apps_manager
    errands_push_usage_service                           = var.errands_push_usage_service
    errands_smbbrokerpush                                = var.errands_smbbrokerpush
    errands_rotate_cc_database_key                       = var.errands_rotate_cc_database_key
    errands_smoke_tests                                  = var.errands_smoke_tests
    errands_test_autoscaling                             = var.errands_test_autoscaling
    system_domain                                        = var.system_domain
    apps_domain                                          = var.apps_domain
    rds_address                                          = var.rds_address
    rds_password                                         = var.rds_password
    rds_port                                             = var.rds_port
    rds_username                                         = var.rds_username
    rds_ca_cert                                          = var.rds_ca_cert_pem
    password_policies_max_retry                          = var.password_policies_max_retry
    password_policies_expires_after_months               = var.password_policies_expires_after_months
    password_policies_max_retry                          = var.password_policies_max_retry
    password_policies_min_length                         = var.password_policies_min_length
    password_policies_min_lowercase                      = var.password_policies_min_lowercase
    password_policies_min_numeric                        = var.password_policies_min_numeric
    password_policies_min_special                        = var.password_policies_min_special
    password_policies_min_uppercase                      = var.password_policies_min_uppercase
    cloud_controller_encrypt_key_secret                  = var.cloud_controller_encrypt_key_secret
    credhub_encryption_password                          = var.credhub_encryption_password
    vanity_cert_pem                                      = var.vanity_cert_pem
    vanity_private_key_pem                               = var.vanity_private_key_pem
    vanity_cert_enabled                                  = var.vanity_cert_enabled
    router_cert_pem                                      = var.router_cert_pem
    router_private_key_pem                               = var.router_private_key_pem
    router_trusted_ca_certificates                       = var.router_trusted_ca_certificates
    smtp_host                                            = var.smtp_host
    smtp_user                                            = var.smtp_user
    smtp_password                                        = var.smtp_password
    smtp_tls                                             = var.smtp_tls
    smtp_from                                            = var.smtp_from
    smtp_port                                            = var.smtp_port
    smtp_enabled                                         = var.smtp_enabled
    uaa_service_provider_key_credentials_cert_pem        = var.uaa_service_provider_key_credentials_cert_pem
    uaa_service_provider_key_credentials_private_key_pem = var.uaa_service_provider_key_credentials_private_key_pem
    apps_manager_global_wrapper_footer_content           = yamlencode({ "value" : var.apps_manager_global_wrapper_footer_content })
    apps_manager_global_wrapper_header_content           = yamlencode({ "value" : var.apps_manager_global_wrapper_header_content })
    apps_manager_tools_url                               = var.apps_manager_tools_url
    apps_manager_about_url                               = var.apps_manager_about_url
    apps_manager_docs_url                                = var.apps_manager_docs_url
    apps_manager_offline_docs_url                        = var.apps_manager_offline_docs_url
    kms_key_id                                           = var.kms_key_id
    pas_buildpacks_bucket                                = var.pas_buildpacks_bucket
    pas_droplets_bucket                                  = var.pas_droplets_bucket
    pas_packages_bucket                                  = var.pas_packages_bucket
    pas_resources_bucket                                 = var.pas_resources_bucket
    pas_buildpacks_backup_bucket                         = var.pas_buildpacks_backup_bucket
    pas_droplets_backup_bucket                           = var.pas_droplets_backup_bucket
    pas_packages_backup_bucket                           = var.pas_packages_backup_bucket
    pas_vpc_azs                                          = indent(4, join("", data.template_file.pas_vpc_azs.*.rendered))
    singleton_availability_zone                          = var.singleton_availability_zone
    syslog_host                                          = var.syslog_host
    syslog_port                                          = var.syslog_port
    apps_syslog_port                                     = var.apps_syslog_port
    syslog_ca_cert                                       = var.syslog_ca_cert
    gorouter_frontend_idle_timeout                       = var.gorouter_frontend_idle_timeout
    gorouter_request_timeout_in_seconds                  = var.gorouter_request_timeout_in_seconds
    use_external_haproxy_endpoint                        = var.use_external_haproxy_endpoint
  })
}



locals {
  haproxy_template = templatefile("${path.module}/haproxy_template.tpl", {
    haproxy_backend_servers        = var.haproxy_backend_servers
    scale                          = var.scale["cf"]
    region                         = var.region
    pas_vpc_azs                    = indent(4, join("", data.template_file.pas_vpc_azs.*.rendered))
    s3_endpoint                    = "https://${var.s3_endpoint}"
    haproxy_elb_names              = "[${join(",", var.haproxy_elb_names)}]"
    system_domain                  = var.system_domain
    vanity_cert_pem                = var.vanity_cert_pem
    vanity_private_key_pem         = var.vanity_private_key_pem
    vanity_cert_enabled            = var.vanity_cert_enabled
    router_cert_pem                = var.router_cert_pem
    router_private_key_pem         = var.router_private_key_pem
    router_trusted_ca_certificates = var.router_trusted_ca_certificates
    singleton_availability_zone    = var.singleton_availability_zone
    syslog_host                    = var.syslog_host
    syslog_port                    = var.syslog_port
    syslog_ca_cert                 = var.syslog_ca_cert
  })
}

resource "tls_private_key" "jwt" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

data "template_file" "portal_template" {
  template = file("${path.module}/portal_yml.tpl")

  vars = {
    ldap_tls_ca_cert       = var.ldap_tls_ca_cert
    ldap_tls_client_cert   = var.ldap_tls_client_cert
    ldap_tls_client_key    = var.ldap_tls_client_key
    ldap_basedn            = var.ldap_basedn
    ldap_dn                = var.ldap_dn
    ldap_password          = var.ldap_password
    ldap_host              = var.ldap_host
    ldap_port              = var.ldap_port
    ldap_role_attr         = var.ldap_role_attr
    mysql_host             = var.rds_address
    mysql_port             = var.rds_port
    mysql_db_name          = "portal"
    mysql_username         = var.rds_username
    mysql_password         = var.rds_password
    mysql_ca_cert          = var.rds_ca_cert_pem
    jwt_key_sign           = tls_private_key.jwt.private_key_pem
    jwt_key_verify         = tls_private_key.jwt.public_key_pem
    system_fqdn            = var.system_domain
    portal_name            = "portal"
    smoke_test_client_cert = var.smoke_test_client_cert
    smoke_test_client_key  = var.smoke_test_client_key
  }
}

data "template_file" "create_db" {
  template = file("${path.module}/create_db.tpl")

  vars = {
    rds_address  = var.rds_address
    rds_password = var.rds_password
    rds_username = var.rds_username

    postgres_host        = var.postgres_host
    postgres_port        = var.postgres_port
    postgres_cw_db_name  = var.postgres_cw_db_name
    postgres_cw_username = var.postgres_cw_username
    postgres_cw_password = var.postgres_cw_password
  }
}

data "template_file" "drop_db" {
  template = file("${path.module}/drop_db.tpl")

  vars = {
    rds_address  = var.rds_address
    rds_password = var.rds_password
    rds_username = var.rds_username
  }
}

resource "aws_s3_bucket_object" "om_drop_db_config" {
  bucket  = var.secrets_bucket_name
  key     = var.om_drop_db_config
  content = data.template_file.drop_db.rendered
}

resource "aws_s3_bucket_object" "om_create_db_config" {
  bucket  = var.secrets_bucket_name
  key     = var.om_create_db_config
  content = data.template_file.create_db.rendered
}

resource "aws_s3_bucket_object" "om_ssh_banner_config" {
  bucket  = var.secrets_bucket_name
  key     = var.om_ssh_banner_config
  content = local.om_ssh_banner_conf
}

resource "aws_s3_bucket_object" "om_ssl_config" {
  bucket  = var.secrets_bucket_name
  key     = var.om_ssl_config
  content = local.om_ssl_conf
}

resource "aws_s3_bucket_object" "om_uaa_password_policy_config" {
  bucket       = var.secrets_bucket_name
  key          = var.om_uaa_password_policy_config
  content_type = "application/json"
  content = jsonencode(
    {
      "password_policy" : {
        "password_min_uppercase" : var.password_policies_min_uppercase,
        "password_min_lowercase" : var.password_policies_min_lowercase,
        "password_min_numeric" : var.password_policies_min_numeric,
        "password_min_special" : var.password_policies_min_special,
        "password_expires_after_months" : var.password_policies_expires_after_months,
        "password_min_length" : var.password_policies_min_length
      }
    }
  )
}

resource "aws_s3_bucket_object" "om_tokens_expiration_config" {
  bucket  = var.secrets_bucket_name
  key     = var.om_tokens_expiration_config
  content = local.om_tokens_expiration_conf
}

resource "aws_s3_bucket_object" "om_syslog_config" {
  bucket  = var.secrets_bucket_name
  key     = var.om_syslog_config
  content = local.om_syslog_conf
}

resource "aws_s3_bucket_object" "portal_template" {
  bucket  = var.secrets_bucket_name
  key     = var.portal_config
  content = data.template_file.portal_template.rendered
}

resource "aws_s3_bucket_object" "director_template" {
  bucket  = var.secrets_bucket_name
  key     = var.director_config
  content = local.director_template
}

resource "aws_s3_bucket_object" "cf_template" {
  bucket  = var.secrets_bucket_name
  key     = var.cf_config
  content = local.cf_template
}

resource "aws_s3_bucket_object" "haproxy_template" {
  bucket  = var.secrets_bucket_name
  key     = var.haproxy_config
  content = local.haproxy_template
}
