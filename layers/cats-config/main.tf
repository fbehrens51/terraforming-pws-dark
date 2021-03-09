provider "aws" {
}

module "providers" {
  source = "../../modules/dark_providers"
}

terraform {
  backend "s3" {
  }
}

data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "paperwork"
    region  = var.remote_state_region
    encrypt = true
  }
}

variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "credhub_password" {
}

variable "admin_password" {
}

variable "cats_config" {
  description = "cats configuration file"
  default     = "cats_config.json"
}

module "domains" {
  source      = "../../modules/domains"
  root_domain = data.terraform_remote_state.paperwork.outputs.root_domain
}

locals {
  cats_template = templatefile("${path.module}/cats_template.tpl", {
    system_fqdn      = module.domains.system_fqdn
    apps_fqdn        = module.domains.apps_fqdn
    credhub_password = var.credhub_password
    admin_password   = var.admin_password
  })
}

resource "aws_s3_bucket_object" "cats_template" {
  bucket  = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
  key     = var.cats_config
  content = local.cats_template
}
