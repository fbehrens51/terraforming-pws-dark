terraform {
  backend "s3" {
  }
}

provider "aws" {
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

data "terraform_remote_state" "bastion" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bastion"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "bind" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bind"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_isolation_segment_vpc_1" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_isolation_segment_vpc_1"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "control-plane-nats" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "control-plane-nats"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "control-plane-ops-manager" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "control-plane-ops-manager"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "enterprise-services" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "enterprise-services"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "fluentd" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "fluentd"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "loki" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "loki"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "ops-manager" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "ops-manager"
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

data "terraform_remote_state" "postfix" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "postfix"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "sjb" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "sjb"
    region  = var.remote_state_region
    encrypt = true
  }
}

locals {
  bot_key_pem         = data.terraform_remote_state.paperwork.outputs.bot_private_key
  enable_bot_user     = var.enable_bot_user
  ssh_key_path        = var.ssh_key_path
  secrets_bucket_name = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
  foundation_name     = data.terraform_remote_state.paperwork.outputs.foundation_name
  bastion_name        = one(keys(data.terraform_remote_state.bastion.outputs.ssh_host_ips))
  cp_om_name          = one(keys(data.terraform_remote_state.control-plane-ops-manager.outputs.ssh_host_ips))
  om_name             = one(keys(data.terraform_remote_state.ops-manager.outputs.ssh_host_ips))
  sjb_name            = one(keys(data.terraform_remote_state.sjb.outputs.ssh_host_ips))

  sshconfig = templatefile("${path.module}/sshconfig.tpl",
    {
      ssh_key_path     = local.ssh_key_path,
      enable_bot_user  = local.enable_bot_user,
      enable_proxyjump = var.enable_proxyjump,
      foundation_name  = local.foundation_name,
      ssh_host_ips = merge(
        data.terraform_remote_state.bind.outputs.ssh_host_ips,
        data.terraform_remote_state.bootstrap_isolation_segment_vpc_1.outputs.ssh_host_ips,
        data.terraform_remote_state.control-plane-ops-manager.outputs.ssh_host_ips,
        data.terraform_remote_state.control-plane-nats.outputs.ssh_host_ips,
        data.terraform_remote_state.enterprise-services.outputs.ssh_host_ips,
        data.terraform_remote_state.fluentd.outputs.ssh_host_ips,
        data.terraform_remote_state.loki.outputs.ssh_host_ips,
        data.terraform_remote_state.ops-manager.outputs.ssh_host_ips,
        data.terraform_remote_state.pas.outputs.ssh_host_ips,
        data.terraform_remote_state.postfix.outputs.ssh_host_ips,
        var.scanner_host_ips,
      ),
      bastion_name = local.bastion_name,
      bosh_name    = "${local.foundation_name}_bosh",
      cp_bosh_name = "${local.foundation_name}_cp_bosh",
      cp_om_name   = local.cp_om_name,
      om_name      = local.om_name,
      sjb_name     = local.sjb_name,
      bastion_ip   = data.terraform_remote_state.bastion.outputs.ssh_host_ips[local.bastion_name],
      bosh_ip      = var.bosh_ip,
      cp_bosh_ip   = var.cp_bosh_ip,
      cp_om_ip     = data.terraform_remote_state.control-plane-ops-manager.outputs.ssh_host_ips[local.cp_om_name],
      om_ip        = data.terraform_remote_state.ops-manager.outputs.ssh_host_ips[local.om_name],
      sjb_ip       = data.terraform_remote_state.sjb.outputs.ssh_host_ips[local.sjb_name],
    }
  )

  ssh_host_ips = merge(
    data.terraform_remote_state.bastion.outputs.ssh_host_ips,
    data.terraform_remote_state.bind.outputs.ssh_host_ips,
    data.terraform_remote_state.bootstrap_isolation_segment_vpc_1.outputs.ssh_host_ips,
    data.terraform_remote_state.control-plane-nats.outputs.ssh_host_ips,
    data.terraform_remote_state.control-plane-ops-manager.outputs.ssh_host_ips,
    data.terraform_remote_state.enterprise-services.outputs.ssh_host_ips,
    data.terraform_remote_state.fluentd.outputs.ssh_host_ips,
    data.terraform_remote_state.loki.outputs.ssh_host_ips,
    data.terraform_remote_state.ops-manager.outputs.ssh_host_ips,
    data.terraform_remote_state.pas.outputs.ssh_host_ips,
    data.terraform_remote_state.postfix.outputs.ssh_host_ips,
    data.terraform_remote_state.sjb.outputs.ssh_host_ips,
    var.scanner_host_ips,
  )
}

variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "bosh_ip" {
  type        = string
  description = "IP address of bosh"
}

variable "cp_bosh_ip" {
  type        = string
  description = "IP address of control_plane bosh"
}

variable "bbr_key" {
  type        = string
  description = "bbr key required to ssh to bosh"
}

variable "cp_bbr_key" {
  type        = string
  description = "control_plane bbr key required to ssh to cp_bosh"
}

variable "enable_proxyjump" {
  type        = bool
  default     = true
  description = "true = outside bastion, false = inside bastion"
}

variable "ssh_key_path" {
  type    = string
  default = "/home/<USER>/.ssh"
}

variable "enable_bot_user" {
  type    = bool
  default = false
}

variable "enable_s3_objects" {
  type        = bool
  default     = true
  description = "enables/disables creation of s3 objects - set to false during development"
}

variable "enable_local_objects" {
  type        = bool
  default     = false
  description = "enables/disables creation of local objects - set to true during development"
}

variable "scanner_host_ips" {
  type        = map(any)
  default     = null
  description = "json object from scanner layer"
}

output "ssh_host_ips" {
  value = local.ssh_host_ips
}

output "sshconfig" {
  value = local.sshconfig
}

resource "aws_s3_bucket_object" "sshconfig" {
  count        = var.enable_s3_objects == true ? 1 : 0
  bucket       = local.secrets_bucket_name
  key          = "sshconfig/${local.foundation_name}_sshconfig"
  content      = local.sshconfig
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "bbr_key" {
  count        = var.enable_s3_objects == true ? 1 : 0
  bucket       = local.secrets_bucket_name
  key          = "sshconfig/${local.foundation_name}_bbr_key.pem"
  content      = var.bbr_key
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "cp_bbr_key" {
  count        = var.enable_s3_objects == true ? 1 : 0
  bucket       = local.secrets_bucket_name
  key          = "sshconfig/${local.foundation_name}_cp_bbr_key.pem"
  content      = var.cp_bbr_key
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "bot_key" {
  count        = var.enable_s3_objects == true ? 1 : 0
  bucket       = local.secrets_bucket_name
  key          = "sshconfig/${local.foundation_name}_bot_key.pem"
  content      = local.bot_key_pem
  content_type = "text/plain"
}

resource "local_file" "sshconfig" {
  count                = var.enable_local_objects == true ? 1 : 0
  content              = local.sshconfig
  filename             = "${var.ssh_key_path}/${local.foundation_name}_sshconfig"
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "local_file" "bbr_key" {
  count                = var.enable_local_objects == true ? 1 : 0
  content              = var.bbr_key
  filename             = "${var.ssh_key_path}/${local.foundation_name}_bbr_key.pem"
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "local_file" "cp_bbr_key" {
  count                = var.enable_local_objects == true ? 1 : 0
  content              = var.cp_bbr_key
  filename             = "${var.ssh_key_path}/${local.foundation_name}_cp_bbr_key.pem"
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "local_file" "bot_key" {
  count                = var.enable_local_objects == true ? 1 : 0
  content              = local.bot_key_pem
  filename             = "${var.ssh_key_path}/${local.foundation_name}_bot_key.pem"
  file_permission      = "0600"
  directory_permission = "0700"
}
