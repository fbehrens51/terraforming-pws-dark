terraform {
  backend "s3" {}
}

module "providers" {
  source = "../../modules/dark_providers"
}

provider "aws" {}

locals {
  cert_bucket                                      = "${replace(var.env_name," ","-")}-secrets"
  root_ca_cert_s3_path                             = "root_ca_cert.pem"
  router_trusted_ca_certs_s3_path                  = "router_trusted_ca_certs.pem"
  trusted_ca_certs_s3_path                         = "trusted_ca_certs.pem"
  rds_ca_cert_s3_path                              = "rds_ca_cert.pem"
  router_server_cert_s3_path                       = "router_server_cert.pem"
  router_server_key_s3_path                        = "router_server_key.pem"
  concourse_server_cert_s3_path                    = "concourse_server_cert.pem"
  concourse_server_key_s3_path                     = "concourse_server_key.pem"
  uaa_server_cert_s3_path                          = "uaa_server_cert.pem"
  uaa_server_key_s3_path                           = "uaa_server_key.pem"
  ldap_client_cert_s3_path                         = "ldap_client_cert.pem"
  ldap_client_key_s3_path                          = "ldap_client_key.pem"
  om_server_cert_s3_path                           = "om_server_cert.pem"
  om_server_key_s3_path                            = "om_server_key.pem"
  control_plane_om_server_cert_s3_path             = "control_plane_om_server_cert.pem"
  control_plane_om_server_key_s3_path              = "control_plane_om_server_key.pem"
  splunk_server_cert_s3_path                       = "splunk_server_cert.pem"
  splunk_server_key_s3_path                        = "splunk_server_key.pem"
  splunk_monitor_server_cert_s3_path               = "splunk_monitor_server_cert.pem"
  splunk_monitor_server_key_s3_path                = "splunk_monitor_server_key.pem"
  portal_smoke_test_cert_s3_path                   = "portal_smoke_test_cert.pem"
  portal_smoke_test_key_s3_path                    = "portal_smoke_test_key.pem"
  ldap_password_s3_path                            = "ldap_password.txt"
  smtp_password_s3_path                            = "smtp_password.txt"
  portal_end_to_end_test_user_cert_pem_path        = "portal_end_to_end_test_user_cert.pem"
  portal_end_to_end_test_user_private_key_pem_path = "portal_end_to_end_test_user_key.pem"

  basedn = "ou=users,dc=${join(",dc=", split(".", var.root_domain))}"
  admin  = "cn=admin,dc=${join(",dc=", split(".", var.root_domain))}"
}

resource "random_string" "ldap_password" {
  length  = "16"
  special = false
}

resource "random_string" "smtp_password" {
  length  = "16"
  special = false
}

module "domains" {
  source = "../../modules/domains"

  root_domain = "${var.root_domain}"
}

module "paperwork" {
  source                = "./modules/paperwork"
  bucket_role_name      = "${var.pas_bucket_role_name}"
  worker_role_name      = "${var.platform_automation_engine_worker_role_name}"
  director_role_name    = "${var.director_role_name}"
  key_manager_role_name = "${var.key_manager_role_name}"
  splunk_role_name      = "${var.splunk_role_name}"

  env_name    = "${var.env_name}"
  root_domain = "${var.root_domain}"
  users       = "${var.users}"
}

data "aws_caller_identity" "current_user" {}

# We invoke the keys layer here to simulate having a KEYMANAGER role invoke keys
# "out of band" in the production environment
module "keys" {
  source = "../../modules/kms/create"

  key_name            = "${var.kms_key_name}"
  director_role_arn   = "${module.paperwork.director_role_arn}"
  pas_bucket_role_arn = "${module.paperwork.pas_bucket_role_arn}"
  deletion_window     = "7"
  additional_bootstrap_principal_arn = "${data.aws_caller_identity.current_user.arn}"
}

resource "aws_s3_bucket" "certs" {
  bucket_prefix = "${local.cert_bucket}"
  acl           = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}

data "template_file" "paperwork_variables" {
  template = "${file("${path.module}/paperwork.tfvars.tpl")}"

  vars {
    root_domain = "${var.root_domain}"

    apps_domain                                 = "${module.domains.apps_fqdn}"
    system_domain                               = "${module.domains.system_fqdn}"
    bucket_role_name                            = "${var.pas_bucket_role_name}"
    platform_automation_engine_worker_role_name = "${var.platform_automation_engine_worker_role_name}"
    splunk_role_name                            = "${var.splunk_role_name}"
    key_manager_role_name                       = "${var.key_manager_role_name}"
    kms_key_id                                  = "${module.keys.kms_key_id}"
    kms_key_arn                                 = "${module.keys.kms_key_arn}"
    director_role_name                          = "${var.director_role_name}"
    sjb_role_name                               = "${var.director_role_name}"
    cp_vpc_id                                   = "${module.paperwork.cp_vpc_id}"
    es_vpc_id                                   = "${module.paperwork.es_vpc_id}"
    bastion_vpc_id                              = "${module.paperwork.bastion_vpc_id}"
    pas_vpc_id                                  = "${module.paperwork.pas_vpc_id}"
    pas_vpc_dns                                 = "${module.paperwork.pas_vpc_dns}"
    control_plane_vpc_dns                       = "${module.paperwork.control_plane_vpc_dns}"

    ldap_basedn           = "${local.basedn}"
    ldap_dn               = "${local.admin}"
    ldap_host             = "${module.domains.ldap_fqdn}"
    ldap_port             = "636"
    ldap_role_attr        = "role"
    ldap_password_s3_path = "${local.ldap_password_s3_path}"

    smtp_password_s3_path = "${local.smtp_password_s3_path}"

    cert_bucket                          = "${aws_s3_bucket.certs.bucket}"
    root_ca_cert_s3_path                 = "${local.root_ca_cert_s3_path}"
    router_trusted_ca_certs_s3_path      = "${local.router_trusted_ca_certs_s3_path}"
    trusted_ca_certs_s3_path             = "${local.trusted_ca_certs_s3_path}"
    rds_ca_cert_s3_path                  = "${local.rds_ca_cert_s3_path}"
    router_server_cert_s3_path           = "${local.router_server_cert_s3_path}"
    router_server_key_s3_path            = "${local.router_server_key_s3_path}"
    concourse_server_cert_s3_path        = "${local.concourse_server_cert_s3_path}"
    concourse_server_key_s3_path         = "${local.concourse_server_key_s3_path}"
    uaa_server_cert_s3_path              = "${local.uaa_server_cert_s3_path}"
    uaa_server_key_s3_path               = "${local.uaa_server_key_s3_path}"
    ldap_client_cert_s3_path             = "${local.ldap_client_cert_s3_path}"
    ldap_client_key_s3_path              = "${local.ldap_client_key_s3_path}"
    om_server_cert_s3_path               = "${local.om_server_cert_s3_path}"
    om_server_key_s3_path                = "${local.om_server_key_s3_path}"
    control_plane_om_server_cert_s3_path = "${local.control_plane_om_server_cert_s3_path}"
    control_plane_om_server_key_s3_path  = "${local.control_plane_om_server_key_s3_path}"
    splunk_server_cert_s3_path           = "${local.splunk_server_cert_s3_path}"
    splunk_server_key_s3_path            = "${local.splunk_server_key_s3_path}"
    splunk_monitor_server_cert_s3_path   = "${local.splunk_monitor_server_cert_s3_path}"
    splunk_monitor_server_key_s3_path    = "${local.splunk_monitor_server_key_s3_path}"
    portal_smoke_test_cert_s3_path       = "${local.portal_smoke_test_cert_s3_path}"
    portal_smoke_test_key_s3_path        = "${local.portal_smoke_test_key_s3_path}"
  }
}

variable "paperwork_variable_output_path" {
  type = "string"
}

variable "platform_automation_engine_worker_role_name" {
  type = "string"
}

variable "pas_bucket_role_name" {
  type = "string"
}

variable "director_role_name" {
  type = "string"
}

variable "key_manager_role_name" {
  type = "string"
}

variable "kms_key_name" {
  type = "string"
}

variable "splunk_role_name" {}

variable "env_name" {
  type = "string"
}

variable "root_domain" {
  type = "string"
}

variable "users" {
  type = "list"
}

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

resource "aws_s3_bucket_object" "rds_ca_cert" {
  key          = "${local.rds_ca_cert_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content      = "${var.rds_ca_cert_pem}"
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

resource "aws_s3_bucket_object" "concourse_server_cert" {
  key          = "${local.concourse_server_cert_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content_type = "text/plain"
  content      = "${module.paperwork.concourse_server_cert}"
}

resource "aws_s3_bucket_object" "concourse_server_key" {
  key          = "${local.concourse_server_key_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content      = "${module.paperwork.concourse_server_key}"
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

resource "aws_s3_bucket_object" "om_server_cert" {
  key          = "${local.om_server_cert_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content      = "${module.paperwork.om_server_cert}"
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "om_server_key" {
  key          = "${local.om_server_key_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content_type = "text/plain"
  content      = "${module.paperwork.om_server_key}"
}

resource "aws_s3_bucket_object" "control_plane_om_server_cert" {
  key          = "${local.control_plane_om_server_cert_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content      = "${module.paperwork.control_plane_om_server_cert}"
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "control_plane_om_server_key" {
  key          = "${local.control_plane_om_server_key_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content_type = "text/plain"
  content      = "${module.paperwork.control_plane_om_server_key}"
}

resource "aws_s3_bucket_object" "splunk_server_cert" {
  key          = "${local.splunk_server_cert_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content      = "${module.paperwork.splunk_server_cert}"
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "splunk_server_key" {
  key          = "${local.splunk_server_key_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content_type = "text/plain"
  content      = "${module.paperwork.splunk_server_key}"
}

resource "aws_s3_bucket_object" "splunk_monitor_server_cert" {
  key          = "${local.splunk_monitor_server_cert_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content      = "${module.paperwork.splunk_monitor_server_cert}"
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "splunk_monitor_server_key" {
  key          = "${local.splunk_monitor_server_key_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content_type = "text/plain"
  content      = "${module.paperwork.splunk_monitor_server_key}"
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
  content      = "${element(module.paperwork.user_certs, index(module.paperwork.usernames, "smoke"))}"
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "portal_smoke_test_key" {
  key          = "${local.portal_smoke_test_key_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content_type = "text/plain"
  content      = "${element(module.paperwork.user_private_keys, index(module.paperwork.usernames, "smoke"))}"
}

resource "aws_s3_bucket_object" "ldap_password" {
  key          = "${local.ldap_password_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content_type = "text/plain"
  content      = "${random_string.ldap_password.result}"
}

resource "aws_s3_bucket_object" "smtp_password" {
  key          = "${local.smtp_password_s3_path}"
  bucket       = "${aws_s3_bucket.certs.bucket}"
  content_type = "text/plain"
  content      = "${random_string.smtp_password.result}"
}

resource "local_file" "paperwork_variables" {
  filename = "${var.paperwork_variable_output_path}"
  content  = "${data.template_file.paperwork_variables.rendered}"
}

# The following outputs are used by the portal test suite and are not needed by the paperwork layer
output "portal_end_to_end_test_user_cert_pem" {
  value = "${module.paperwork.portal_end_to_end_test_user_cert_pem}"
}

output "portal_end_to_end_test_user_private_key_pem" {
  value     = "${module.paperwork.portal_end_to_end_test_user_private_key_pem}"
  sensitive = true
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

output "usernames" {
  value     = "${module.paperwork.usernames}"
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

variable "rds_ca_cert_pem" {
  type = "string"
}

variable "additional_trusted_ca_certs" {
  type    = "string"
  default = ""
}
