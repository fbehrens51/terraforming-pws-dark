terraform {
  backend "s3" {}
}

module "providers" {
  source = "../../modules/dark_providers"
}

provider "aws" {
  region = "${var.region}"
}

locals {
  ldap_domain   = "ldap.${var.root_domain}"
  system_domain = "run.${var.root_domain}"
  apps_domain   = "cfapps.${var.root_domain}"

  cert_bucket                     = "pws-dark-ci-certs"
  root_ca_cert_s3_path            = "root_ca_cert.pem"
  router_trusted_ca_certs_s3_path = "router_trusted_ca_certs.pem"
  trusted_ca_certs_s3_path        = "trusted_ca_certs.pem"
  router_server_cert_s3_path      = "router_server_cert.pem"
  router_server_key_s3_path       = "router_server_key.pem"
  uaa_server_cert_s3_path         = "uaa_server_cert.pem"
  uaa_server_key_s3_path          = "uaa_server_key.pem"
  ldap_client_cert_s3_path        = "ldap_client_cert.pem"
  ldap_client_key_s3_path         = "ldap_client_key.pem"
  portal_smoke_test_cert_s3_path  = "portal_smoke_test_cert.pem"
  portal_smoke_test_key_s3_path   = "portal_smoke_test_key.pem"
  ldap_password_s3_path           = "ldap_password.txt"

  basedn = "ou=users,dc=${join(",dc=", split(".", var.root_domain))}"
  admin  = "cn=admin,dc=${join(",dc=", split(".", var.root_domain))}"
}

resource "random_string" "ldap_password" {
  length  = "16"
  special = false
}

module "paperwork" {
  source                = "./modules/paperwork"
  bucket_role_name      = "${var.bucket_role_name}"
  director_role_name    = "${var.director_role_name}"
  key_manager_role_name = "${var.key_manager_role_name}"
  splunk_role_name      = "${var.splunk_role_name}"

  env_name      = "${var.env_name}"
  root_domain   = "${var.root_domain}"
  ldap_domain   = "${local.ldap_domain}"
  system_domain = "${local.system_domain}"
  apps_domain   = "${local.apps_domain}"
  users         = "${var.users}"
}

resource "aws_s3_bucket" "certs" {
  bucket = "${local.cert_bucket}"
  acl    = "private"
}

data "template_file" "paperwork_variables" {
  template = "${file("${path.module}/paperwork.tfvars.tpl")}"

  vars {
    apps_domain           = "${local.apps_domain}"
    system_domain         = "${local.system_domain}"
    bucket_role_name      = "${var.bucket_role_name}"
    splunk_role_name      = "${var.splunk_role_name}"
    key_manager_role_name = "${var.key_manager_role_name}"
    director_role_name    = "${var.director_role_name}"
    cp_vpc_id             = "${module.paperwork.cp_vpc_id}"
    es_vpc_id             = "${module.paperwork.es_vpc_id}"
    bastion_vpc_id        = "${module.paperwork.bastion_vpc_id}"
    pas_vpc_id            = "${module.paperwork.pas_vpc_id}"

    ldap_basedn           = "${local.basedn}"
    ldap_dn               = "${local.admin}"
    ldap_host             = "${local.ldap_domain}"
    ldap_port             = "636"
    ldap_role_attr        = "role"
    ldap_password_s3_path = "${local.ldap_password_s3_path}"

    cert_bucket                     = "${local.cert_bucket}"
    root_ca_cert_s3_path            = "${local.root_ca_cert_s3_path}"
    router_trusted_ca_certs_s3_path = "${local.router_trusted_ca_certs_s3_path}"
    trusted_ca_certs_s3_path        = "${local.trusted_ca_certs_s3_path}"
    router_server_cert_s3_path      = "${local.router_server_cert_s3_path}"
    router_server_key_s3_path       = "${local.router_server_key_s3_path}"
    uaa_server_cert_s3_path         = "${local.uaa_server_cert_s3_path}"
    uaa_server_key_s3_path          = "${local.uaa_server_key_s3_path}"
    ldap_client_cert_s3_path        = "${local.ldap_client_cert_s3_path}"
    ldap_client_key_s3_path         = "${local.ldap_client_key_s3_path}"
    portal_smoke_test_cert_s3_path  = "${local.portal_smoke_test_cert_s3_path}"
    portal_smoke_test_key_s3_path   = "${local.portal_smoke_test_key_s3_path}"
  }
}

variable "paperwork_variable_output_path" {
  type = "string"
}

variable "bucket_role_name" {
  type = "string"
}

variable "director_role_name" {
  type = "string"
}

variable "key_manager_role_name" {
  type = "string"
}

variable "splunk_role_name" {}

variable "env_name" {
  type = "string"
}

variable "root_domain" {
  type = "string"
}

variable "region" {
  type = "string"
}

variable "users" {
  type = "list"
}

variable "cert_bucket_kms_key_id" {}

resource "aws_s3_bucket_object" "router_trusted_ca_certs" {
  key          = "${local.router_trusted_ca_certs_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content      = "${module.paperwork.router_trusted_ca_certs}"
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "root_ca_cert" {
  key          = "${local.root_ca_cert_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content      = "${module.paperwork.root_ca_cert}"
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "trusted_ca_certs" {
  key          = "${local.trusted_ca_certs_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content      = "${module.paperwork.trusted_ca_certs}${var.additional_trusted_ca_certs}"
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "router_server_cert" {
  key          = "${local.router_server_cert_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content_type = "text/plain"
  content      = "${module.paperwork.router_server_cert}"
}

resource "aws_s3_bucket_object" "router_server_key" {
  key          = "${local.router_server_key_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content      = "${module.paperwork.router_server_key}"
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "uaa_server_cert" {
  key          = "${local.uaa_server_cert_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content      = "${module.paperwork.uaa_server_cert}"
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "uaa_server_key" {
  key          = "${local.uaa_server_key_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content      = "${module.paperwork.uaa_server_key}"
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "ldap_client_cert" {
  key          = "${local.ldap_client_cert_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content      = "${module.paperwork.ldap_client_cert}"
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "ldap_client_key" {
  key          = "${local.ldap_client_key_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content_type = "text/plain"
  content      = "${module.paperwork.ldap_client_key}"
}

resource "aws_s3_bucket_object" "portal_smoke_test_cert" {
  key          = "${local.portal_smoke_test_cert_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content      = "${lookup(module.paperwork.user_certs, "smoke")}"
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "portal_smoke_test_key" {
  key          = "${local.portal_smoke_test_key_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content_type = "text/plain"
  content      = "${lookup(module.paperwork.user_private_keys, "smoke")}"
}

resource "aws_s3_bucket_object" "ldap_password" {
  key          = "${local.ldap_password_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content_type = "text/plain"
  content      = "${random_string.ldap_password.result}"
}

resource "local_file" "paperwork_variables" {
  filename = "${var.paperwork_variable_output_path}"
  content  = "${data.template_file.paperwork_variables.rendered}"
}

# The following outputs are used by the ldap layer but are not needed by the
# paperwork layer
output "ldap_server_cert" {
  value = "${module.paperwork.ldap_server_cert}"
}

output "ldap_server_key" {
  value     = "${module.paperwork.ldap_server_key}"
  sensitive = true
}

output "user_private_keys" {
  value     = "${module.paperwork.user_private_keys}"
  sensitive = true
}

output "user_certs" {
  value     = "${module.paperwork.user_certs}"
  sensitive = true
}

variable "additional_trusted_ca_certs" {
  type    = "string"
  default = ""
}
