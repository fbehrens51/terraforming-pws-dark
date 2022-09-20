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

module "vanity2_server_cert" {
  source             = "../server_cert"
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  env_name           = var.env_name
  common_name        = "vanity2"
  domains            = ["*.web.eagle"]
}

module "fluentd_server_cert" {
  source             = "../server_cert"
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  env_name           = var.env_name
  common_name        = module.domains.fluentd_subdomain
  domains            = [module.domains.fluentd_fqdn]
}

module "loki_server_cert" {
  source             = "../server_cert"
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  env_name           = var.env_name
  common_name        = module.domains.loki_subdomain
  domains            = [module.domains.loki_fqdn]
}

module "smtp_server_cert" {
  source             = "../server_cert"
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  env_name           = var.env_name
  common_name        = module.domains.smtp_subdomain
  domains            = [module.domains.smtp_fqdn]
}

module "control_plane_star_server_cert" {
  source = "../server_cert"

  env_name           = var.env_name
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  common_name        = module.domains.control_plane_star_subdomain
  domains            = [module.domains.control_plane_star_fqdn]
}

module "om_server_cert" {
  source = "../server_cert"

  env_name           = var.env_name
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  common_name        = module.domains.om_subdomain
  domains            = [module.domains.om_fqdn]
}

// TODO[#177504576]: the new ldap server does not support client auth, do we want to keep this?
module "ldap_client_cert" {
  source = "../client_cert"

  env_name           = var.env_name
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  common_name        = "LDAP Client"
  ou                 = "Applications"
}

module "loki_client_cert" {
  source = "../client_cert"

  env_name           = var.env_name
  ca_cert_pem        = module.ca_cert.cert_pem
  ca_private_key_pem = module.ca_cert.private_key_pem
  common_name        = "Loki Client"
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

