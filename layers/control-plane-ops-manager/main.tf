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

variable "om_user_data_path" {
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
  user_data            = data.template_cloudinit_config.config.rendered

  root_block_device = {
    volume_type = "gp2"
    volume_size = 150
  }
}

variable "clamav_deb_pkg_object_key" {
}

module "clam_av_client_config" {
  source           = "../../modules/clamav/ubuntu_systemd_client"
  clamav_db_mirror = "database.clamav.net"
  deb_tgz_location = "${data.terraform_remote_state.paperwork.outputs.public_bucket_url}/${var.clamav_deb_pkg_object_key}"
}

data "template_cloudinit_config" "config" {
  base64_encode = true
  gzip          = true

  part {
    content_type = "text/cloud-config"
    content      = file(var.om_user_data_path)
  }

  part {
    content_type = "text/cloud-config"

    content = <<CLOUDINIT
bootcmd:
  # Disable SSL in postgres.  Otherwise, postgres will fail to start since the
  # snakeoil certificate is missing.  Note that OM connect to postgres over the
  # unix socket.
  - sudo sed -i 's/^ssl = true/#ssl = true/' /etc/postgresql/*/main/postgresql.conf
CLOUDINIT

  }

  part {
    filename     = "clamav.cfg"
    content_type = "text/cloud-config"
    content      = module.clam_av_client_config.client_user_data_config
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "banner.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.custom_banner_user_data
  }
}

resource "aws_eip_association" "om_eip_assoc" {
  count         = length(local.om_eip_allocation) > 0 ? 1 : 0
  instance_id   = module.ops_manager.instance_ids[0]
  allocation_id = local.om_eip_allocation[0].id
}

output "ops_manager_private_ip" {
  value = module.ops_manager.private_ips[0]
}

