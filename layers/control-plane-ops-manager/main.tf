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
  director_role_name          = data.terraform_remote_state.paperwork.outputs.director_role_name
  om_ssh_public_key_pair_name = data.terraform_remote_state.bootstrap_control_plane.outputs.om_ssh_public_key_pair_name
  om_eip_allocation           = data.terraform_remote_state.bootstrap_control_plane.outputs.om_eip_allocation
  om_eni_id                   = data.terraform_remote_state.bootstrap_control_plane.outputs.om_eni_id

  tags = merge(
    var.tags,
    {
      "Name" = "${var.env_name}-ops-manager"
    },
  )
  trusted_ca_certs        = data.terraform_remote_state.paperwork.outputs.trusted_with_additional_ca_certs
  user_accounts_user_data = data.terraform_remote_state.paperwork.outputs.user_accounts_user_data
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

module "ops_manager" {
  instance_count = "1"

  source               = "../../modules/launch"
  ami_id               = var.om_ami_id
  iam_instance_profile = local.director_role_name
  instance_type        = var.instance_type
  key_pair_name        = local.om_ssh_public_key_pair_name
  tags                 = local.tags
  eni_ids              = [local.om_eni_id]
  user_data            = module.ops_manager_user_data.cloud_config

  root_block_device = {
    volume_type = "gp2"
    volume_size = 150
  }
}

variable "clamav_db_mirror" {
}

variable "clamav_deb_pkg_object_url" {
}

module "clam_av_client_config" {
  source           = "../../modules/clamav/ubuntu_systemd_client"
  clamav_db_mirror = var.clamav_db_mirror
  deb_tgz_location = "${var.clamav_deb_pkg_object_url}"
}

module "ops_manager_user_data" {
  source                    = "../../modules/ops_manager_user_data"
  customer_banner_user_data = data.terraform_remote_state.paperwork.outputs.custom_banner_user_data
  clamav_client_user_data   = module.clam_av_client_config.client_user_data_config
  user_accounts_user_data   = local.user_accounts_user_data
  trusted_ca_certs          = local.trusted_ca_certs
}

resource "aws_eip_association" "om_eip_assoc" {
  count         = length(local.om_eip_allocation) > 0 ? 1 : 0
  instance_id   = module.ops_manager.instance_ids[0]
  allocation_id = local.om_eip_allocation[0].id
}

output "ops_manager_private_ip" {
  value = module.ops_manager.private_ips[0]
}

