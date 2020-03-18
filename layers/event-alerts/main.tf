provider "aws" {
}

terraform {
  backend "s3" {
  }
}

module "providers" {
  source = "../../modules/dark_providers"
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

data "terraform_remote_state" "bootstrap_postfix" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_postfix"
    region  = var.remote_state_region
    encrypt = true
  }
}

locals {
  rds_engine         = "mariadb"
  rds_engine_version = "10.3"
  database_name      = "alerts"

  root_domain = data.terraform_remote_state.paperwork.outputs.root_domain

  pas_network_name = data.terraform_remote_state.paperwork.outputs.pas_network_name
  rds_ca_cert_pem  = data.terraform_remote_state.paperwork.outputs.rds_ca_cert
  pas_vpc_id       = data.terraform_remote_state.paperwork.outputs.pas_vpc_id

  rds_subnet_group_name = data.terraform_remote_state.pas.outputs.rds_subnet_group_name
  pas_rds_cidr_block    = data.terraform_remote_state.pas.outputs.rds_cidr_block

  smtp_host     = module.domains.smtp_fqdn
  smtp_port     = data.terraform_remote_state.bootstrap_postfix.outputs.smtp_client_port
  smtp_user     = data.terraform_remote_state.bootstrap_postfix.outputs.smtp_client_user
  smtp_password = data.terraform_remote_state.bootstrap_postfix.outputs.smtp_client_password

  env_name      = var.tags["Name"]
  modified_name = "${local.env_name}-event-alerts"
  modified_tags = merge(
    var.tags,
    {
      "Name" = local.modified_name
    },
  )
}

module "domains" {
  source      = "../../modules/domains"
  root_domain = local.root_domain
}

module "event_alerts_config" {
  source = "../../modules/event_alerts/config"

  bosh_network_name           = local.pas_network_name
  availability_zones          = var.availability_zones
  singleton_availability_zone = var.singleton_availability_zone
  pas_rds_cidr_block          = local.pas_rds_cidr_block

  mysql_host            = module.rds.rds_address
  mysql_port            = module.rds.rds_port
  mysql_username        = var.rds_db_username
  mysql_password        = module.rds.rds_password
  mysql_name            = local.database_name
  mysql_ca_cert         = local.rds_ca_cert_pem
  mysql_use_tls         = "false"
  mysql_tls_skip_verify = "false"

  smtp_host            = local.smtp_host
  smtp_username        = local.smtp_user
  smtp_password        = local.smtp_password
  smtp_port            = local.smtp_port
  smtp_tls_enabled     = "true"
  smtp_tls_skip_verify = "true"
  smtp_from            = var.smtp_from
}

module "rds" {
  source = "../../modules/rds/instance"

  rds_db_username    = var.rds_db_username
  rds_instance_class = var.rds_instance_class

  engine = local.rds_engine

  # RDS decided to upgrade the patch version automatically from 10.1.31 to
  # 10.1.34, which makes terraform see this as a change.  Use a prefix version
  # to prevent this from happening.
  engine_version = local.rds_engine_version

  db_port = 3306

  env_name = local.modified_name
  vpc_id   = local.pas_vpc_id
  tags     = local.modified_tags

  subnet_group_name    = local.rds_subnet_group_name
  parameter_group_name = aws_db_parameter_group.event-alerts.id
  database_name        = local.database_name
  kms_key_id           = data.terraform_remote_state.paperwork.outputs.kms_key_arn
}

resource "aws_db_parameter_group" "event-alerts" {
  name   = "${replace(lower(local.modified_name), " ", "-")}-parameter-group"
  family = "${local.rds_engine}${local.rds_engine_version}"
  tags   = local.modified_tags
  parameter {
    name  = "log_bin_trust_function_creators"
    value = "1"
  }
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

variable "env_name" {
}

variable "tags" {
  type = map(string)
}

variable "rds_db_username" {
}

variable "rds_instance_class" {
}

variable "smtp_from" {
}

output "rds_address" {
  value = module.rds.rds_address
}

output "rds_password" {
  value     = module.rds.rds_password
  sensitive = true
}

output "rds_port" {
  value = module.rds.rds_port
}

output "rds_username" {
  value = module.rds.rds_username
}

output "event_alerts_config" {
  value     = module.event_alerts_config.event_alerts_config
  sensitive = true
}
