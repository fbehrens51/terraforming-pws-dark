variable "global_vars" {
  type = any
}

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

variable "region" {
}

variable "force_destroy_buckets" {
  type    = bool
  default = false
}

terraform {
  backend "s3" {
  }
}

data "aws_region" "current" {
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

module "domains" {
  source = "../../modules/domains"

  root_domain = local.root_domain
}

module "syslog_ports" {
  source = "../../modules/syslog_ports"
}

locals {
  env_name       = var.global_vars.env_name
  bucket_name    = "${replace(local.env_name, " ", "-")}-compliance-scans-cp"
  root_domain    = data.terraform_remote_state.paperwork.outputs.root_domain
  s3_logs_bucket = data.terraform_remote_state.paperwork.outputs.s3_logs_bucket
}

module "compliance_scanner_config" {
  source                      = "../../modules/compliance-scanner/config"
  scale                       = data.terraform_remote_state.scaling-params.outputs.instance_types
  secrets_bucket_name         = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
  compliance_scanner_config   = var.compliance_scanner_config
  network_name                = data.terraform_remote_state.paperwork.outputs.control_plane_subnet_network_name
  availability_zones          = var.availability_zones
  singleton_availability_zone = var.singleton_availability_zone
  ntp_servers                 = var.ntp_servers
  syslog_host                 = module.domains.fluentd_fqdn
  syslog_port                 = module.syslog_ports.syslog_port
  syslog_ca_cert              = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs
  custom_ssh_banner           = data.terraform_remote_state.paperwork.outputs.custom_ssh_banner
  reports_bucket_name         = local.bucket_name
  reports_bucket_region       = data.aws_region.current.name
}

resource "aws_s3_bucket" "compliance_scanner_bucket" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy_buckets

  versioning {
    enabled = false
  }

  logging {
    target_bucket = local.s3_logs_bucket
    target_prefix = "log/"
  }

  tags = merge(
    var.global_vars["global_tags"],
    {
      "Name" = "Compliance Scanner Results Bucket"
    },
  )
}
