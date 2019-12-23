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

variable "network_name" {
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

module "metrics_config" {
  source                      = "../../modules/metrics/config"
  bosh_network_name           = var.network_name
  availability_zones          = var.availability_zones
  singleton_availability_zone = var.singleton_availability_zone

  splunk_syslog_host    = module.domains.splunk_logs_fqdn
  splunk_syslog_port    = module.splunk_ports.splunk_tcp_port
  splunk_syslog_ca_cert = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs
}

output "metrics_config" {
  value     = module.metrics_config.metrics_config
  sensitive = true
}

