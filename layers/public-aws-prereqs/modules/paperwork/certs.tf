variable "splunk_domain" {}
variable "ldap_domain" {}
variable "apps_domain" {}
variable "system_domain" {}

module "ca_cert" {
  source = "../ca_cert"

  env_name = "${var.env_name}"
}

module "splunk_server_cert" {
  source = "../server_cert"

  env_name           = "${var.env_name}"
  ca_cert_pem        = "${module.ca_cert.cert_pem}"
  ca_private_key_pem = "${module.ca_cert.private_key_pem}"
  common_name        = "splunk"
  domains            = ["${var.splunk_domain}"]
}

module "ldap_server_cert" {
  source = "../server_cert"

  env_name           = "${var.env_name}"
  ca_cert_pem        = "${module.ca_cert.cert_pem}"
  ca_private_key_pem = "${module.ca_cert.private_key_pem}"
  common_name        = "LDAP"
  domains            = ["${var.ldap_domain}"]
}

module "ldap_client_cert" {
  source = "../client_cert"

  env_name           = "${var.env_name}"
  ca_cert_pem        = "${module.ca_cert.cert_pem}"
  ca_private_key_pem = "${module.ca_cert.private_key_pem}"
  common_name        = "LDAP Client"
}

module "router_server_cert" {
  source = "../server_cert"

  env_name           = "${var.env_name}"
  ca_cert_pem        = "${module.ca_cert.cert_pem}"
  ca_private_key_pem = "${module.ca_cert.private_key_pem}"
  common_name        = "${var.env_name} Router"

  domains = [
    "*.${var.system_domain}",
    "*.${var.apps_domain}",
  ]
}

module "uaa_server_cert" {
  source = "../server_cert"

  env_name           = "${var.env_name}"
  ca_cert_pem        = "${module.ca_cert.cert_pem}"
  ca_private_key_pem = "${module.ca_cert.private_key_pem}"
  common_name        = "${var.env_name} UAA"

  domains = [
    "login.${var.system_domain}",
  ]
}
