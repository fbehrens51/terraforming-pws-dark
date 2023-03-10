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

variable "metrics_config" {
  default = "pas/metrics_tile_config.yml"
}

variable "metrics_store_config" {
  default = "pas/metrics_store_tile_config.yml"
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

data "terraform_remote_state" "scaling-params" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "scaling-params"
    region  = var.remote_state_region
    encrypt = true
  }
}

module "domains" {
  source = "../../modules/domains"

  root_domain = local.root_domain
}

module "syslog_ports" {
  source = "../../modules/syslog_ports"
}

locals {
  root_domain         = data.terraform_remote_state.paperwork.outputs.root_domain
  secrets_bucket_name = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
  api_endpoint        = "https://api.${module.domains.system_fqdn}"
}

module "metrics_config" {
  source                      = "../../modules/metrics/config"
  scale                       = data.terraform_remote_state.scaling-params.outputs.instance_types
  secrets_bucket_name         = local.secrets_bucket_name
  metrics_config              = var.metrics_config
  metrics_store_config        = var.metrics_store_config
  bosh_network_name           = data.terraform_remote_state.paperwork.outputs.pas_network_name
  availability_zones          = var.availability_zones
  singleton_availability_zone = var.singleton_availability_zone

  syslog_host    = module.domains.fluentd_fqdn
  syslog_port    = module.syslog_ports.syslog_port
  syslog_ca_cert = data.terraform_remote_state.paperwork.outputs.syslog_ca_certs_bundle
}
