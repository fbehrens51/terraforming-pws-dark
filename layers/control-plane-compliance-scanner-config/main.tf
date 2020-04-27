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

variable "ntp_servers" {
  type = list(string)
}

variable "compliance_scanner_config" {
  default = "control_plane/compliance_scanner_config.yml"
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
}

module "compliance_scanner_config" {
  source                      = "../../modules/compliance-scanner/config"
  secrets_bucket_name         = local.secrets_bucket_name
  compliance_scanner_config   = var.compliance_scanner_config
  network_name                = data.terraform_remote_state.paperwork.outputs.control_plane_subnet_network_name
  availability_zones          = var.availability_zones
  singleton_availability_zone = var.singleton_availability_zone
  ntp_servers                 = var.ntp_servers
  splunk_syslog_host          = module.domains.fluentd_fqdn
  splunk_syslog_port          = module.splunk_ports.splunk_tcp_port
  splunk_syslog_ca_cert       = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs
  custom_ssh_banner           = data.terraform_remote_state.paperwork.outputs.custom_ssh_banner
}
