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

module "fluentd_server_cert" {
  source             = "../server_cert"
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  env_name           = var.env_name
  common_name        = module.domains.fluentd_subdomain
  domains            = [module.domains.fluentd_fqdn]
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
  ou                 = "People"
}

module "portal_end_to_end_test_application_cert" {
  source = "../client_cert"

  env_name           = var.env_name
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  common_name        = "PortalEndToEndTestUser"
  ou                 = "Applications"
}

module "portal_end_to_end_test_application_certB" {
  source = "../client_cert"

  env_name           = var.env_name
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  common_name        = "PortalEndToEndTestUser"
  ou                 = "Applications"
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
  ou                 = "Applications"
}

module "grafana_server_cert" {
  source = "../server_cert"

  env_name           = var.env_name
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  common_name        = "${var.env_name} Grafana"

  domains = [
    module.domains.grafana_fqdn,
  ]
}

module "router_server_cert" {
  source = "../server_cert"

  env_name           = var.env_name
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  common_name        = "${var.env_name} Router"

  domains = [
    "*.${module.domains.system_fqdn}",
    "*.login.${module.domains.system_fqdn}",
    "*.uaa.${module.domains.system_fqdn}",
    "*.${module.domains.apps_fqdn}",
  ]
}

module "concourse_credhub_server_cert" {
  source = "../server_cert"

  env_name           = var.env_name
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  common_name        = "${var.env_name} Concourse_credhub"

  domains = [
    module.domains.control_plane_plane_fqdn,
  ]
}

module "concourse_uaa_server_cert" {
  source = "../server_cert"

  env_name           = var.env_name
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  common_name        = "${var.env_name} Concourse_uaa"

  domains = [
    module.domains.control_plane_uaa_fqdn,
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

