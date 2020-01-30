module "ca_cert" {
  source = "../ca_cert"

  env_name = var.env_name
}

module "domains" {
  source = "../../../../modules/domains"

  root_domain = var.root_domain
}

module "vanity_server_cert" {
  source             = "../server_cert"
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  env_name           = var.env_name
  common_name        = "vanity"
  domains            = ["*.eagle"]
}

module "smtp_server_cert" {
  source             = "../server_cert"
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  env_name           = var.env_name
  common_name        = module.domains.smtp_subdomain
  domains            = [module.domains.smtp_fqdn]
}

module "portal_end_to_end_test_user_cert" {
  source = "../client_cert"

  env_name           = var.env_name
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  common_name        = "PortalEndToEndTestUser"
}

module "splunk_server_cert" {
  source = "../server_cert"

  env_name           = var.env_name
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  common_name        = module.domains.splunk_subdomain
  domains            = [module.domains.splunk_fqdn]
}

module "splunk_logs_server_cert" {
  source = "../server_cert"

  env_name           = var.env_name
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  common_name        = module.domains.splunk_logs_subdomain
  domains            = [module.domains.splunk_logs_fqdn]
}

module "control_plane_om_server_cert" {
  source = "../server_cert"

  env_name           = var.env_name
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  common_name        = module.domains.control_plane_om_subdomain
  domains            = [module.domains.control_plane_om_fqdn]
}

module "om_server_cert" {
  source = "../server_cert"

  env_name           = var.env_name
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  common_name        = module.domains.om_subdomain
  domains            = [module.domains.om_fqdn]
}

module "splunk_monitor_server_cert" {
  source = "../server_cert"

  env_name           = var.env_name
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  common_name        = module.domains.splunk_monitor_subdomain
  domains            = [module.domains.splunk_monitor_fqdn]
}

module "ldap_server_cert" {
  source = "../server_cert"

  env_name           = var.env_name
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  common_name        = "LDAP Server"
  ips                = [var.ldap_eip]
}

module "ldap_client_cert" {
  source = "../client_cert"

  env_name           = var.env_name
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  common_name        = "LDAP Client"
}

module "router_server_cert" {
  source = "../server_cert"

  env_name           = var.env_name
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  common_name        = "${var.env_name} Router"

  domains = [
    "*.${module.domains.system_fqdn}",
    "*.${module.domains.apps_fqdn}",
  ]
}

module "concourse_server_cert" {
  source = "../server_cert"

  env_name           = var.env_name
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  common_name        = "${var.env_name} Concourse"

  domains = [
    module.domains.control_plane_plane_fqdn,
  ]
}

module "uaa_server_cert" {
  source = "../server_cert"

  env_name           = var.env_name
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  common_name        = "${var.env_name} UAA"

  domains = [
    "login.${module.domains.system_fqdn}",
  ]
}

