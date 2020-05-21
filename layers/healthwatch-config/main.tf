variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "smtp_from" {
  default = ""
}

//from global vars
variable "availability_zones" {
  type = list(string)
}

variable "singleton_availability_zone" {
}

variable "env_name" {
}

variable "region" {
}

variable "healthwatch_config" {
  default = "pas/healthwatch_config.yml"
}

variable "healthwatch_pas_exporter_config" {
  default = "pas/healthwatch_pas_exporter_config.yml"
}

terraform {
  backend "s3" {
  }
}

module "providers" {
  source = "../../modules/dark_providers"
}

data "terraform_remote_state" "bootstrap_postfix" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_postfix"
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
  root_domain         = data.terraform_remote_state.paperwork.outputs.root_domain
  secrets_bucket_name = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
  smtp_client_user    = data.terraform_remote_state.bootstrap_postfix.outputs.smtp_client_user
}

module "healthwatch_config" {
  source                          = "../../modules/healthwatch/config"
  secrets_bucket_name             = local.secrets_bucket_name
  healthwatch_config              = var.healthwatch_config
  healthwatch_pas_exporter_config = var.healthwatch_pas_exporter_config
  grafana_elb_id                  = data.terraform_remote_state.pas.outputs.grafana_elb_id
  grafana_server_ca_cert          = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs
  grafana_server_cert             = data.terraform_remote_state.paperwork.outputs.grafana_server_cert
  grafana_server_key              = data.terraform_remote_state.paperwork.outputs.grafana_server_key
  root_domain                     = local.root_domain
  network_name                    = data.terraform_remote_state.paperwork.outputs.pas_network_name
  availability_zones              = var.availability_zones
  singleton_availability_zone     = var.singleton_availability_zone
  health_check_availability_zone  = var.singleton_availability_zone
  bosh_task_uaa_client_secret     = random_string.healthwatch_client_credentials_secret.result
  region                          = var.region
  metrics_key                     = data.terraform_remote_state.paperwork.outputs.metrics_key
  grafana_uaa_client_secret       = random_string.grafana_uaa_client_secret.result

  syslog_host           = module.domains.fluentd_fqdn
  syslog_port           = module.splunk_ports.splunk_tcp_port
  splunk_syslog_ca_cert = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs

  smtp_from            = var.smtp_from
  smtp_host            = "smtp.${local.root_domain}"
  smtp_client_password = data.terraform_remote_state.bootstrap_postfix.outputs.smtp_client_password
  smtp_client_port     = data.terraform_remote_state.bootstrap_postfix.outputs.smtp_client_port
  smtp_client_user     = "${local.smtp_client_user}@${local.root_domain}"
}

resource "random_string" "healthwatch_client_credentials_secret" {
  length  = "32"
  special = false
}

output "healthwatch_client_credentials_secret" {
  value     = random_string.healthwatch_client_credentials_secret.result
  sensitive = true
}

resource "random_string" "grafana_uaa_client_secret" {
  length  = "32"
  special = false
}

output "grafana_uaa_client_secret" {
  value     = random_string.grafana_uaa_client_secret.result
  sensitive = true
}

