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

variable "splunk_nozzle_config" {
  default = "pas/splunk_nozzle_config.yml"
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

data "terraform_remote_state" "bootstrap_splunk" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_splunk"
    region  = var.remote_state_region
    encrypt = true
  }
}

locals {
  api_endpoint                = "https://api.${data.terraform_remote_state.paperwork.outputs.system_domain}"
  secrets_bucket_name         = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
  splunk_http_collector_url   = data.terraform_remote_state.bootstrap_splunk.outputs.splunk_http_collector_url
  splunk_http_collector_token = data.terraform_remote_state.bootstrap_splunk.outputs.splunk_http_collector_token
}

module "firehose_config" {
  source                      = "../../modules/splunk/firehose-nozzle_config"
  secrets_bucket_name         = local.secrets_bucket_name
  splunk_config               = var.splunk_nozzle_config
  api_endpoint                = local.api_endpoint
  splunk_url                  = local.splunk_http_collector_url
  splunk_token                = local.splunk_http_collector_token
  client_secret               = data.terraform_remote_state.bootstrap_splunk.outputs.cf_splunk_password
  network_name                = data.terraform_remote_state.paperwork.outputs.infrastructure_network_name
  availability_zones          = var.availability_zones
  singleton_availability_zone = var.singleton_availability_zone
}
