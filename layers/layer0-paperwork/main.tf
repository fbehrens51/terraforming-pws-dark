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

  env_name = "${var.env_name}"
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

output "bucket_role_name" {
  value = "${var.bucket_role_name}"
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

variable "region" {
  type = "string"
}