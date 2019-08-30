terraform {
  backend "s3" {}
}

module "providers" {
  source = "../../modules/dark_providers"
}

provider "aws" {}

variable "cert_bucket" {}

variable "pas_vpc_id" {}

variable "pas_vpc_dns" {}

variable "bastion_vpc_id" {}

variable "es_vpc_id" {}

variable "cp_vpc_id" {}

variable "director_role_name" {}

variable "key_manager_role_name" {}

variable "kms_key_id" {}

variable "splunk_role_name" {}

variable "bucket_role_name" {}

variable "ldap_basedn" {}

variable "ldap_dn" {}

variable "ldap_host" {}

variable "ldap_port" {}

variable "ldap_role_attr" {}

variable "system_domain" {}

variable "apps_domain" {}

variable "ldap_password_s3_path" {}

data "aws_s3_bucket_object" "ldap_password" {
  bucket = "${var.cert_bucket}"
  key    = "${var.ldap_password_s3_path}"
}

variable "root_ca_cert_s3_path" {}

data "aws_s3_bucket_object" "root_ca_cert" {
  bucket = "${var.cert_bucket}"
  key    = "${var.root_ca_cert_s3_path}"
}

variable "router_trusted_ca_certs_s3_path" {}

data "aws_s3_bucket_object" "router_trusted_ca_certs" {
  bucket = "${var.cert_bucket}"
  key    = "${var.router_trusted_ca_certs_s3_path}"
}

variable "trusted_ca_certs_s3_path" {}

data "aws_s3_bucket_object" "trusted_ca_certs" {
  bucket = "${var.cert_bucket}"
  key    = "${var.trusted_ca_certs_s3_path}"
}

variable "rds_ca_cert_s3_path" {}

data "aws_s3_bucket_object" "rds_ca_cert" {
  bucket = "${var.cert_bucket}"
  key    = "${var.rds_ca_cert_s3_path}"
}

variable "router_server_cert_s3_path" {}

data "aws_s3_bucket_object" "router_server_cert" {
  bucket = "${var.cert_bucket}"
  key    = "${var.router_server_cert_s3_path}"
}

variable "router_server_key_s3_path" {}

data "aws_s3_bucket_object" "router_server_key" {
  bucket = "${var.cert_bucket}"
  key    = "${var.router_server_key_s3_path}"
}

variable "uaa_server_cert_s3_path" {}

data "aws_s3_bucket_object" "uaa_server_cert" {
  bucket = "${var.cert_bucket}"
  key    = "${var.uaa_server_cert_s3_path}"
}

variable "uaa_server_key_s3_path" {}

data "aws_s3_bucket_object" "uaa_server_key" {
  bucket = "${var.cert_bucket}"
  key    = "${var.uaa_server_key_s3_path}"
}

variable "ldap_client_cert_s3_path" {}

data "aws_s3_bucket_object" "ldap_client_cert" {
  bucket = "${var.cert_bucket}"
  key    = "${var.ldap_client_cert_s3_path}"
}

variable "ldap_client_key_s3_path" {}

data "aws_s3_bucket_object" "ldap_client_key" {
  bucket = "${var.cert_bucket}"
  key    = "${var.ldap_client_key_s3_path}"
}

variable "om_server_cert_s3_path" {}

data "aws_s3_bucket_object" "om_server_cert" {
  bucket = "${var.cert_bucket}"
  key    = "${var.om_server_cert_s3_path}"
}

variable "om_server_key_s3_path" {}

data "aws_s3_bucket_object" "om_server_key" {
  bucket = "${var.cert_bucket}"
  key    = "${var.om_server_key_s3_path}"
}

variable "splunk_server_cert_s3_path" {}

data "aws_s3_bucket_object" "splunk_server_cert" {
  bucket = "${var.cert_bucket}"
  key    = "${var.splunk_server_cert_s3_path}"
}

variable "splunk_server_key_s3_path" {}

data "aws_s3_bucket_object" "splunk_server_key" {
  bucket = "${var.cert_bucket}"
  key    = "${var.splunk_server_key_s3_path}"
}

variable "splunk_monitor_server_cert_s3_path" {}

data "aws_s3_bucket_object" "splunk_monitor_server_cert" {
  bucket = "${var.cert_bucket}"
  key    = "${var.splunk_monitor_server_cert_s3_path}"
}

variable "splunk_monitor_server_key_s3_path" {}

data "aws_s3_bucket_object" "splunk_monitor_server_key" {
  bucket = "${var.cert_bucket}"
  key    = "${var.splunk_monitor_server_key_s3_path}"
}

variable "portal_smoke_test_cert_s3_path" {}

data "aws_s3_bucket_object" "portal_smoke_test_cert" {
  bucket = "${var.cert_bucket}"
  key    = "${var.portal_smoke_test_cert_s3_path}"
}

variable "portal_smoke_test_key_s3_path" {}

data "aws_s3_bucket_object" "portal_smoke_test_key" {
  bucket = "${var.cert_bucket}"
  key    = "${var.portal_smoke_test_key_s3_path}"
}

output "pas_vpc_dns" {
  value = "${var.pas_vpc_dns}"
}

output "pas_vpc_id" {
  value = "${var.pas_vpc_id}"
}

output "bastion_vpc_id" {
  value = "${var.bastion_vpc_id}"
}

output "es_vpc_id" {
  value = "${var.es_vpc_id}"
}

output "cp_vpc_id" {
  value = "${var.cp_vpc_id}"
}

output "director_role_name" {
  value = "${var.director_role_name}"
}

output "key_manager_role_name" {
  value = "${var.key_manager_role_name}"
}

output "kms_key_id" {
  value = "${var.kms_key_id}"
}

output "splunk_role_name" {
  value = "${var.splunk_role_name}"
}

output "root_ca_cert" {
  value = "${data.aws_s3_bucket_object.root_ca_cert.body}"
}

output "router_trusted_ca_certs" {
  value = "${data.aws_s3_bucket_object.router_trusted_ca_certs.body}"
}

output "trusted_ca_certs" {
  value = "${data.aws_s3_bucket_object.trusted_ca_certs.body}"
}

output "rds_ca_cert" {
  value = "${data.aws_s3_bucket_object.rds_ca_cert.body}"
}

output "router_server_cert" {
  value = "${data.aws_s3_bucket_object.router_server_cert.body}"
}

output "router_server_key" {
  value     = "${data.aws_s3_bucket_object.router_server_key.body}"
  sensitive = true
}

output "uaa_server_cert" {
  value = "${data.aws_s3_bucket_object.uaa_server_cert.body}"
}

output "uaa_server_key" {
  value     = "${data.aws_s3_bucket_object.uaa_server_key.body}"
  sensitive = true
}

output "ldap_client_cert" {
  value = "${data.aws_s3_bucket_object.ldap_client_cert.body}"
}

output "ldap_client_key" {
  value     = "${data.aws_s3_bucket_object.ldap_client_key.body}"
  sensitive = true
}

output "om_server_cert" {
  value = "${data.aws_s3_bucket_object.om_server_cert.body}"
}

output "om_server_key" {
  value     = "${data.aws_s3_bucket_object.om_server_key.body}"
  sensitive = true
}

output "splunk_server_cert" {
  value = "${data.aws_s3_bucket_object.splunk_server_cert.body}"
}

output "splunk_server_key" {
  value     = "${data.aws_s3_bucket_object.splunk_server_key.body}"
  sensitive = true
}

output "splunk_monitor_server_cert" {
  value = "${data.aws_s3_bucket_object.splunk_monitor_server_cert.body}"
}

output "splunk_monitor_server_key" {
  value     = "${data.aws_s3_bucket_object.splunk_monitor_server_key.body}"
  sensitive = true
}

output "portal_smoke_test_cert" {
  value = "${data.aws_s3_bucket_object.portal_smoke_test_cert.body}"
}

output "portal_smoke_test_key" {
  value     = "${data.aws_s3_bucket_object.portal_smoke_test_key.body}"
  sensitive = true
}

output "bucket_role_name" {
  value = "${var.bucket_role_name}"
}

output "ldap_basedn" {
  value = "${var.ldap_basedn}"
}

output "ldap_dn" {
  value = "${var.ldap_dn}"
}

output "ldap_password" {
  value     = "${data.aws_s3_bucket_object.ldap_password.body}"
  sensitive = true
}

output "ldap_host" {
  value = "${var.ldap_host}"
}

output "ldap_port" {
  value = "${var.ldap_port}"
}

output "ldap_role_attr" {
  value = "${var.ldap_role_attr}"
}

output "system_domain" {
  value = "${var.system_domain}"
}

output "apps_domain" {
  value = "${var.apps_domain}"
}
