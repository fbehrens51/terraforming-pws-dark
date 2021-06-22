provider "aws" {
}

module "providers" {
  source = "../../modules/dark_providers"
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

data "terraform_remote_state" "scaling-params" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "scaling-params"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_control_plane" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_control_plane"
    region  = var.remote_state_region
    encrypt = true
  }
}

locals {
  om_role_name               = data.terraform_remote_state.paperwork.outputs.om_role_name
  om_role_id                 = data.terraform_remote_state.paperwork.outputs.om_role_id
  director_role_name         = data.terraform_remote_state.paperwork.outputs.director_role_name
  director_role_id           = data.terraform_remote_state.paperwork.outputs.director_role_id
  super_user_role_ids        = data.terraform_remote_state.paperwork.outputs.super_user_role_ids
  isse_role_id               = data.terraform_remote_state.paperwork.outputs.isse_role_id
  ent_tech_read_role_id      = data.terraform_remote_state.paperwork.outputs.ent_tech_read_role_id
  super_user_id              = data.terraform_remote_state.paperwork.outputs.super_user_ids
  om_eni_id                  = data.terraform_remote_state.bootstrap_control_plane.outputs.om_eni_id
  env_name                   = var.global_vars.env_name
  modified_name              = "${var.global_vars.name_prefix} cp ops-manager"
  modified_tags              = merge(
  var.global_vars["global_tags"],
  var.global_vars["instance_tags"],
  {
    "Name"       = local.modified_name
    "MetricsKey" = data.terraform_remote_state.paperwork.outputs.metrics_key,
    "job"        = "cp_ops_manager",
  },
  )
  om_user_accounts_user_data = data.terraform_remote_state.paperwork.outputs.om_user_accounts_user_data
}

variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "om_ami_id" {
}

variable "global_vars" {
  type = any
}

variable "clamav_db_mirror" {
}

variable "clamav_deb_pkg_object_url" {
}

module "ops_manager" {
  instance_count = "1"

  source               = "../../modules/launch"
  ami_id               = var.om_ami_id
  iam_instance_profile = local.om_role_name
  instance_types       = data.terraform_remote_state.scaling-params.outputs.instance_types
  scale_vpc_key        = "control-plane"
  scale_service_key    = "ops-manager"
  tags                 = local.modified_tags
  eni_ids              = [local.om_eni_id]
  user_data            = module.ops_manager_user_data.cloud_config
  bot_key_pem          = data.terraform_remote_state.paperwork.outputs.bot_private_key
  cloud_init_timeout   = 600

  root_block_device = {
    volume_type = "gp2"
    volume_size = 150
  }
}

module "ops_manager_user_data" {
  source                    = "../../modules/ops_manager_user_data"
  customer_banner_user_data = data.terraform_remote_state.paperwork.outputs.custom_banner_user_data
  user_accounts_user_data   = local.om_user_accounts_user_data
  node_exporter_user_data   = data.terraform_remote_state.paperwork.outputs.node_exporter_user_data
  clamav_db_mirror          = var.clamav_db_mirror
  clamav_deb_pkg_object_url = var.clamav_deb_pkg_object_url
  tag_completion_user_data  = data.terraform_remote_state.paperwork.outputs.completion_tag_om_user_data
}

module "ops_manager_backup_bucket_policy" {
  source     = "../../modules/bucket/policy/generic"
  bucket_arn = data.terraform_remote_state.bootstrap_control_plane.outputs.ops_manager_bucket_arn

  read_write_role_ids = concat(local.super_user_role_ids, [local.director_role_id, local.om_role_id])
  read_write_user_ids = local.super_user_role_ids
  read_only_role_ids  = [local.isse_role_id, local.ent_tech_read_role_id]
  disable_delete      = false
}

resource "aws_s3_bucket_policy" "ops_manager_backup_bucket_policy_attachment" {
  bucket = data.terraform_remote_state.bootstrap_control_plane.outputs.ops_manager_bucket_name
  policy = module.ops_manager_backup_bucket_policy.json
}

output "ops_manager_private_ip" {
  value = module.ops_manager.private_ips[0]
}

