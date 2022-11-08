variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "availability_zones" {
  type = list(string)
}

variable "singleton_availability_zone" {
}

variable "spring_gateway_config" {
  default = "pas/spring_cloud_gateway_tile_config.yml"
}

variable "java_buildpack" {
  type = string
  default = "java_buildpack_offline"
  description = "java buildback for the service instance to use"
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

data "terraform_remote_state" "scaling-params" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "scaling-params"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "aws_vpc" "pas_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
}

module "domains" {
  source      = "../../modules/domains"
  root_domain = data.terraform_remote_state.paperwork.outputs.root_domain
}

module "syslog_ports" {
  source = "../../modules/syslog_ports"
}

locals {
  secrets_bucket_name = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
}

module "spring_gateway_config" {
  source                      = "../../modules/spring_gateway/config"
  scale                       = data.terraform_remote_state.scaling-params.outputs.instance_types
  secrets_bucket_name         = local.secrets_bucket_name
  spring_gateway_config       = var.spring_gateway_config
  network_name                = data.terraform_remote_state.paperwork.outputs.pas_network_name
  availability_zones          = var.availability_zones
  singleton_availability_zone = var.singleton_availability_zone
  syslog_host                 = module.domains.fluentd_fqdn
  syslog_port                 = module.syslog_ports.syslog_port
  syslog_ca_cert              = data.terraform_remote_state.paperwork.outputs.syslog_ca_certs_bundle
}
