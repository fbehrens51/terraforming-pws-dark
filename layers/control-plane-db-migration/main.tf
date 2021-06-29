provider "aws" {
}

module "providers" {
  source = "../../modules/dark_providers"
}

terraform {
  backend "s3" {
  }
}

variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

data "terraform_remote_state" "bootstrap_control_plane_foundation" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_control_plane_foundation"
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


variable "global_vars" {
  type = any
}

variable "rds_instance_class" {
  default = "db.m4.large"
}
variable "parameter_group_name" {
  default = null
}

variable "database_name" {
  default = null
}

locals {
  env_name      = var.global_vars.name_prefix
  modified_name = "${local.env_name} control plane"
  modified_tags = merge(
    var.global_vars["global_tags"],
    {
      "Name"       = local.modified_name
      "MetricsKey" = data.terraform_remote_state.paperwork.outputs.metrics_key,
    },
  )

  tags = local.modified_tags

  rds_username          = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.mysql_rds_username
  rds_password          = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.mysql_rds_password
  rds_subnet_group_name = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.mysql_rds_subnet_group_name
  kms_key_id            = data.terraform_remote_state.paperwork.outputs.kms_key_arn
  identifier            = replace("${local.env_name}-control-plane-mysql-mysql", " ", "-")

}

data "aws_security_group" "rds_security_group" {
  name = "${local.env_name} control plane mysql rds security group"
}

resource "aws_db_instance" "rds" {
  allocated_storage           = 100
  instance_class              = var.rds_instance_class
  engine                      = "mysql"
  engine_version              = "5.7"
  identifier                  = local.identifier
  username                    = local.rds_username
  password                    = local.rds_password
  db_subnet_group_name        = local.rds_subnet_group_name
  publicly_accessible         = false
  vpc_security_group_ids      = [data.aws_security_group.rds_security_group.id]
  iops                        = 1000
  multi_az                    = true
  skip_final_snapshot         = true
  backup_retention_period     = 7
  apply_immediately           = true
  allow_major_version_upgrade = true

  delete_automated_backups = false

  # Next to paramaters are optional, default to null in TF v0.12
  parameter_group_name = var.parameter_group_name
  name                 = var.database_name

  kms_key_id        = local.kms_key_id
  storage_encrypted = true

  tags = local.tags
}

resource "aws_db_parameter_group" "mariabdb-read-only" {
  name        = "mariadb-read-only"
  family      = "mariadb10.2"
  description = "MariaDB read only"
}

output "rds_mariadb_identifier" {
  value = local.identifier
}