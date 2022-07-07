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

data "terraform_remote_state" "control-plane-nats" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "control-plane-nats"
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
  bastion_ip          = data.terraform_remote_state.bastion.outputs.ssh_host_ips[local.bastion_name]
  bastion_name        = one(keys(data.terraform_remote_state.bastion.outputs.ssh_host_ips))
  bot_key_pem         = data.terraform_remote_state.paperwork.outputs.bot_private_key
  foundation_name     = data.terraform_remote_state.paperwork.outputs.foundation_name
  secrets_bucket_name = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
  sjb_ip              = data.terraform_remote_state.sjb.outputs.ssh_host_ips[local.sjb_name]
  sjb_name            = one(keys(data.terraform_remote_state.sjb.outputs.ssh_host_ips))
  ssh_key_path        = var.ssh_key_path
  loki_ssh_host_ips   = data.terraform_remote_state.paperwork.outputs.enable_loki == true ? data.terraform_remote_state.loki[0].outputs.ssh_host_ips : {}
  sshconfig_host_ips = merge(
    data.terraform_remote_state.bind.outputs.ssh_host_ips,
    data.terraform_remote_state.control-plane-nats.outputs.ssh_host_ips,
    data.terraform_remote_state.enterprise-services.outputs.ssh_host_ips,
    data.terraform_remote_state.fluentd.outputs.ssh_host_ips,
    data.terraform_remote_state.postfix.outputs.ssh_host_ips,
    local.loki_ssh_host_ips,
    var.scanner_host_ips,
  )

  common_params = {
    bastion_ip      = local.bastion_ip,
    bastion_name    = local.bastion_name,
    foundation_name = local.foundation_name,
    sjb_ip          = local.sjb_ip,
    sjb_name        = local.sjb_name,
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
  key          = "sshconfig/${local.foundation_name}_base_sshconfig_outside"
  content      = local.sshconfig_outside
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "sshconfig_bastion" {
  count        = var.enable_s3_objects == true ? 1 : 0
  bucket       = local.secrets_bucket_name
  key          = "sshconfig/${local.foundation_name}_base_sshconfig_bastion"
  content      = local.sshconfig_bastion
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "sshconfig_sjb" {
  count        = var.enable_s3_objects == true ? 1 : 0
  bucket       = local.secrets_bucket_name
  key          = "sshconfig/${local.foundation_name}_base_sshconfig_sjb"
  content      = local.sshconfig_sjb
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
  filename             = "${var.ssh_key_path}/${local.foundation_name}_base_sshconfig_outside"
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "local_file" "sshconfig_bastion" {
  count                = var.enable_local_objects == true ? 1 : 0
  content              = local.sshconfig_bastion
  filename             = "${var.ssh_key_path}/${local.foundation_name}_base_sshconfig_bastion"
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "local_file" "sshconfig_sjb" {
  count                = var.enable_local_objects == true ? 1 : 0
  content              = local.sshconfig_sjb
  filename             = "${var.ssh_key_path}/${local.foundation_name}_base_sshconfig_sjb"
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
