variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

//from global vars
variable "availability_zones" {
  type = list(string)
}

variable "singleton_availability_zone" {
}

variable "env_name" {
}

terraform {
  backend "s3" {
  }
}

module "providers" {
  source = "../../modules/dark_providers"
}

data "terraform_remote_state" "bootstrap_splunk" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_splunk"
    region  = var.remote_state_region
    encrypt = true
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

data "terraform_remote_state" "pas" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "pas"
    region  = var.remote_state_region
    encrypt = true
  }
}

module "domains" {
  source = "../../modules/domains"

  root_domain = local.root_domain
}

module "splunk_ports" {
  source = "../../modules/splunk_ports"
}

locals {
  root_domain  = data.terraform_remote_state.paperwork.outputs.root_domain
  api_endpoint = "https://api.${module.domains.system_fqdn}"
}

module "healthwatch_config" {
  source                         = "../../modules/healthwatch/config"
  om_url                         = "https://${module.domains.om_fqdn}"
  network_name                   = data.terraform_remote_state.paperwork.outputs.pas_network_name
  availability_zones             = var.availability_zones
  singleton_availability_zone    = var.singleton_availability_zone
  health_check_availability_zone = var.singleton_availability_zone
  env_name                       = var.env_name
  bosh_task_uaa_client_secret    = random_string.healthwatch_client_credentials_secret.result

  splunk_syslog_host    = module.domains.splunk_logs_fqdn
  splunk_syslog_port    = module.splunk_ports.splunk_tcp_port
  splunk_syslog_ca_cert = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs
}

resource "random_string" "healthwatch_client_credentials_secret" {
  length  = "32"
  special = false
}

output "healthwatch_config" {
  value     = module.healthwatch_config.healthwatch_config
  sensitive = true
}

output "healthwatch_client_credentials_secret" {
  value     = random_string.healthwatch_client_credentials_secret.result
  sensitive = true
}

