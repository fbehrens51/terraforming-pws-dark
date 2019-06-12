variable "root_domain" {}

module "ca_cert" {
  source = "../ca_cert"

  env_name = "${var.env_name}"
}

module "ldap_server_cert" {
  source = "../server_cert"

  env_name = "${var.env_name}"
  ca_cert_pem = "${module.ca_cert.cert_pem}"
  ca_private_key_pem = "${module.ca_cert.private_key_pem}"
  common_name = "LDAP"
  domains = ["ldap.${var.root_domain}"]
}
