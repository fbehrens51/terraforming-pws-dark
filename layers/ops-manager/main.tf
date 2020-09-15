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

data "terraform_remote_state" "bastion" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bastion"
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

locals {
  director_role_name = data.terraform_remote_state.paperwork.outputs.director_role_name
  om_eni_id          = data.terraform_remote_state.pas.outputs.om_eni_id

  tags = merge(
    var.tags,
    {
      "Name"       = "${var.env_name}-ops-manager"
      "MetricsKey" = data.terraform_remote_state.paperwork.outputs.metrics_key
    },
  )

  om_user_accounts_user_data = data.terraform_remote_state.paperwork.outputs.om_user_accounts_user_data
}

variable "internetless" {
}

variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "om_ami_id" {
}

variable "env_name" {
}

variable "tags" {
  type = map(string)
}

variable "instance_type" {
}

variable "clamav_deb_pkg_object_url" {
}

variable "clamav_db_mirror" {
}

module "ops_manager_user_data" {
  source                    = "../../modules/ops_manager_user_data"
  customer_banner_user_data = data.terraform_remote_state.paperwork.outputs.custom_banner_user_data
  user_accounts_user_data   = local.om_user_accounts_user_data
  node_exporter_user_data   = data.terraform_remote_state.paperwork.outputs.node_exporter_user_data
  clamav_db_mirror          = var.clamav_db_mirror
  clamav_deb_pkg_object_url = var.clamav_deb_pkg_object_url
}



module "ops_manager" {
  instance_count = "1"

  source               = "../../modules/launch"
  ami_id               = var.om_ami_id
  iam_instance_profile = local.director_role_name
  instance_type        = var.instance_type
  tags                 = local.tags
  eni_ids              = [local.om_eni_id]
  user_data            = module.ops_manager_user_data.cloud_config
  bot_key_pem          = data.terraform_remote_state.paperwork.outputs.bot_private_key
  bastion_host         = var.internetless ? null : data.terraform_remote_state.bastion.outputs.bastion_ip

  root_block_device = {
    volume_type = "gp2"
    volume_size = 150
  }
}

output "ops_manager_private_ip" {
  value = module.ops_manager.private_ips[0]
}

