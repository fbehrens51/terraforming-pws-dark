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
  count   = (data.terraform_remote_state.paperwork.outputs.enable_loki == true ? 1 : 0)
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

data "terraform_remote_state" "tkg-jumpbox" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "tkg-jumpbox"
    region  = var.remote_state_region
    encrypt = true
  }
}

locals {
  bastion_ip          = data.terraform_remote_state.bastion.outputs.ssh_host_ips[local.bastion_name]
  bastion_name        = one(keys(data.terraform_remote_state.bastion.outputs.ssh_host_ips))
  bot_key_pem         = data.terraform_remote_state.paperwork.outputs.bot_private_key
  cp_om_ip            = data.terraform_remote_state.control-plane-ops-manager.outputs.ssh_host_ips[local.cp_om_name]
  cp_om_name          = one(keys(data.terraform_remote_state.control-plane-ops-manager.outputs.ssh_host_ips))
  foundation_name     = data.terraform_remote_state.paperwork.outputs.foundation_name
  om_ip               = data.terraform_remote_state.ops-manager.outputs.ssh_host_ips[local.om_name]
  om_name             = one(keys(data.terraform_remote_state.ops-manager.outputs.ssh_host_ips))
  secrets_bucket_name = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
  sjb_ip              = data.terraform_remote_state.sjb.outputs.ssh_host_ips[local.sjb_name]
  sjb_name            = one(keys(data.terraform_remote_state.sjb.outputs.ssh_host_ips))
  tkgjb_name          = one(keys(data.terraform_remote_state.tkg-jumpbox.outputs.ssh_host_ips))
  tkgjb_ip            = data.terraform_remote_state.tkg-jumpbox.outputs.ssh_host_ips[local.tkgjb_name]
  ssh_key_path        = var.ssh_key_path
  loki_ssh_host_ips   = data.terraform_remote_state.paperwork.outputs.enable_loki == true ? data.terraform_remote_state.loki[0].outputs.ssh_host_ips : {}
  sshconfig_host_ips  = merge(
  data.terraform_remote_state.bind.outputs.ssh_host_ips,
  data.terraform_remote_state.bootstrap_isolation_segment_vpc_1.outputs.ssh_host_ips,
  data.terraform_remote_state.control-plane-ops-manager.outputs.ssh_host_ips,
  data.terraform_remote_state.control-plane-nats.outputs.ssh_host_ips,
  data.terraform_remote_state.enterprise-services.outputs.ssh_host_ips,
  data.terraform_remote_state.fluentd.outputs.ssh_host_ips,
  data.terraform_remote_state.ops-manager.outputs.ssh_host_ips,
  data.terraform_remote_state.pas.outputs.ssh_host_ips,
  data.terraform_remote_state.postfix.outputs.ssh_host_ips,
  local.loki_ssh_host_ips,
  var.scanner_host_ips,
  data.terraform_remote_state.tkg-jumpbox.outputs.ssh_host_ips,
  )

  common_params     = {
    bastion_ip      = local.bastion_ip,
    bastion_name    = local.bastion_name,
    bosh_ip         = var.bosh_ip,
    bosh_name       = "${local.foundation_name}_bosh",
    cp_bosh_ip      = var.cp_bosh_ip,
    cp_bosh_name    = "${local.foundation_name}_cp_bosh",
    cp_om_ip        = local.cp_om_ip,
    cp_om_name      = local.cp_om_name,
    foundation_name = local.foundation_name,
    om_ip           = local.om_ip,
    om_name         = local.om_name,
    sjb_ip          = local.sjb_ip,
    sjb_name        = local.sjb_name,
    tkgjb_ip        = local.tkgjb_ip,
    tkgjb_name      = local.tkgjb_name,
    ssh_host_ips    = local.sshconfig_host_ips
    ssh_key_path    = local.ssh_key_path,
  }
  sshconfig_outside = templatefile("${path.module}/sshconfig.tpl",
  merge(local.common_params,
  {
    enable_bastion_proxyjump = true,
    enable_sjb_proxyjump     = true,
  }
  )
  )

  sshconfig_bastion = templatefile("${path.module}/sshconfig.tpl",
  merge(local.common_params,
  {
    enable_bastion_proxyjump = false,
    enable_sjb_proxyjump     = true,
  }
  )
  )

  sshconfig_sjb = templatefile("${path.module}/sshconfig.tpl",
  merge(local.common_params,
  {
    enable_bastion_proxyjump = false,
    enable_sjb_proxyjump     = false,
  }
  )
  )

  ssh_host_ips = merge(
  local.sshconfig_host_ips,
  data.terraform_remote_state.bastion.outputs.ssh_host_ips,
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

variable "ssh_key_path" {
  type    = string
  default = "~/.ssh"
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

resource "aws_s3_bucket_object" "sshconfig_outside" {
  count        = var.enable_s3_objects == true ? 1 : 0
  bucket       = local.secrets_bucket_name
  key          = "sshconfig/${local.foundation_name}_sshconfig_outside"
  content      = local.sshconfig_outside
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "sshconfig_bastion" {
  count        = var.enable_s3_objects == true ? 1 : 0
  bucket       = local.secrets_bucket_name
  key          = "sshconfig/${local.foundation_name}_sshconfig_bastion"
  content      = local.sshconfig_bastion
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "sshconfig_sjb" {
  count        = var.enable_s3_objects == true ? 1 : 0
  bucket       = local.secrets_bucket_name
  key          = "sshconfig/${local.foundation_name}_sshconfig_sjb"
  content      = local.sshconfig_sjb
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

resource "local_file" "sshconfig_outside" {
  count                = var.enable_local_objects == true ? 1 : 0
  content              = local.sshconfig_outside
  filename             = "${var.ssh_key_path}/${local.foundation_name}_sshconfig_outside"
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "local_file" "sshconfig_bastion" {
  count                = var.enable_local_objects == true ? 1 : 0
  content              = local.sshconfig_bastion
  filename             = "${var.ssh_key_path}/${local.foundation_name}_sshconfig_bastion"
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "local_file" "sshconfig_sjb" {
  count                = var.enable_local_objects == true ? 1 : 0
  content              = local.sshconfig_sjb
  filename             = "${var.ssh_key_path}/${local.foundation_name}_sshconfig_sjb"
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
