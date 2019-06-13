terraform {
  backend "s3" {}
}

module "providers" {
  source = "../../modules/dark_providers"
}

provider "aws" {
  region = "${var.region}"
}

module "paperwork" {
  source                = "./modules/paperwork"
  bucket_role_name      = "${var.bucket_role_name}"
  director_role_name    = "${var.director_role_name}"
  key_manager_role_name = "${var.key_manager_role_name}"

  env_name    = "${var.env_name}"
  root_domain = "${var.root_domain}"
  users       = "${var.users}"
}

output "pas_vpc_id" {
  value = "${module.paperwork.pas_vpc_id}"
}

output "bastion_vpc_id" {
  value = "${module.paperwork.bastion_vpc_id}"
}

output "es_vpc_id" {
  value = "${module.paperwork.es_vpc_id}"
}

output "cp_vpc_id" {
  value = "${module.paperwork.cp_vpc_id}"
}

output "director_role_name" {
  value = "${var.director_role_name}"
}

output "root_ca_cert" {
  value = "${module.paperwork.root_ca_cert}"
}

output "ldap_server_cert" {
  value     = "${module.paperwork.ldap_server_cert}"
  sensitive = true
}

output "ldap_server_key" {
  value     = "${module.paperwork.ldap_server_key}"
  sensitive = true
}

output "ldap_client_cert" {
  value     = "${module.paperwork.ldap_client_cert}"
  sensitive = true
}

output "ldap_client_key" {
  value     = "${module.paperwork.ldap_client_key}"
  sensitive = true
}

output "user_private_keys" {
  value = "${module.paperwork.user_private_keys}"
}

output "user_certs" {
  value = "${module.paperwork.user_certs}"
}

output "bucket_role_name" {
  value = "${var.bucket_role_name}"
}

output "ldap_host" {
  value = "ldap.${var.root_domain}"
}

variable "users" {
  type = "list"
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

variable "env_name" {
  type = "string"
}

variable "root_domain" {
  type = "string"
}

variable "region" {
  type = "string"
}
