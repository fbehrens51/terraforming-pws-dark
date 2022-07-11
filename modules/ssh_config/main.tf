locals {

  bastion_name = "${var.foundation_name}_bastion"
  sjb_name     = "${var.foundation_name}_sjb"

  common_params = {
    foundation_name     = var.foundation_name,
    ssh_user            = var.ssh_user,
    bastion_name        = local.bastion_name
    sjb_name            = local.sjb_name
    ssh_host_ips        = var.host_ips
    ssh_host_prefix     = var.host_type
    ssh_key_path        = var.ssh_key_path,
    custom_ssh_key      = var.custom_ssh_key,
    include_base_config = var.include_base_config
  }

  is_sjb     = (var.host_type == "sjb" ? true : false)
  is_bastion = (var.host_type == "bastion" ? true : false)
  is_base    = (var.host_type == "base" ? true : false)

  sshconfig_outside = templatefile("${path.module}/sshconfig.tpl",
    merge(local.common_params,
      {
        proxy_jump           = (local.is_sjb ? local.bastion_name : var.custom_inner_proxy),
        enable_sjb_proxyjump = (local.is_base ? true : false),
      }
    )
  )
  sshconfig_bastion = templatefile("${path.module}/sshconfig.tpl",
    merge(local.common_params,
      {
        proxy_jump           = var.custom_inner_proxy,
        enable_sjb_proxyjump = (local.is_base ? true : false),
      }
    )
  )
  sshconfig_sjb = templatefile("${path.module}/sshconfig.tpl",
    merge(local.common_params,
      {
        proxy_jump           = var.custom_inner_proxy,
        enable_sjb_proxyjump = false,
      }
    )
  )
}

variable "custom_inner_proxy" {
  type        = string
  default     = ""
  description = "custom inner_proxy"
}

variable "include_base_config" {
  type        = bool
  default     = false
  description = "Whether or not to include the base sshconfig settings in the generated config"
}

variable "enable_sjb_proxyjump" {
  type        = bool
  default     = false
  description = "Whether or not to include the custom sjb proxyjump config"
}

variable "foundation_name" {
  type        = string
  description = "foundation_name used for the sshconfig"
}

variable "ssh_user" {
  type        = string
  default     = ""
  description = "user used for the provided host's sshconfig"
}

variable "host_type" {
  type        = string
  description = "type of host used for name prefix in sshconfig"
}

variable "host_ips" {
  description = "list of hostname, IP address(es)"
  default     = []
}

variable "custom_ssh_key" {
  type        = string
  default     = ""
  description = "custom ssh key required to ssh to provided host(s)"
}

variable "ssh_key_path" {
  type    = string
  default = "~/.ssh"
}

variable "secrets_bucket_name" {
  type        = string
  description = "name of the bucket to write config to"
}

output "ssh_config_outside" {
  value = local.sshconfig_outside
}

output "ssh_config_bastion" {
  value = local.sshconfig_outside
}

output "ssh_config_sjb" {
  value = local.sshconfig_outside
}

resource "aws_s3_bucket_object" "sshconfig_outside" {
  bucket       = var.secrets_bucket_name
  key          = "sshconfig/outside/${var.foundation_name}_${var.host_type}_sshconfig"
  content      = local.sshconfig_outside
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "sshconfig_bastion" {
  count        = (local.is_bastion ? 0 : 1)
  bucket       = var.secrets_bucket_name
  key          = "sshconfig/bastion/${var.foundation_name}_${var.host_type}_sshconfig"
  content      = local.sshconfig_bastion
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "sshconfig_sjb" {
  count        = (local.is_sjb ? 0 : (local.is_bastion ? 0 : 1))
  bucket       = var.secrets_bucket_name
  key          = "sshconfig/sjb/${var.foundation_name}_${var.host_type}_sshconfig"
  content      = local.sshconfig_sjb
  content_type = "text/plain"
}