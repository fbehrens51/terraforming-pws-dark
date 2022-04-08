variable "custom_ssh_banner" {
  type        = string
  description = "Custom SSH Banner to be used on launched VMs"
}

variable "s3_endpoint" {
}

variable "region" {
}

variable "runtime_config" {
}

locals {
  runtime_config_file_glob    = "pws-dark-runtime-config*.pivotal"
  runtime_config_product_slug = "pws-dark-runtime-config-tile"
}

resource "aws_s3_bucket_object" "runtime_config_template" {
  bucket = var.secrets_bucket_name
  key    = var.runtime_config
  content = templatefile("${path.module}/runtime_config_template.tpl", {
    runtime_config     = var.runtime_config
    ssh_banner  = var.custom_ssh_banner
    extra_users = var.extra_users
  })
}

variable "secrets_bucket_name" {
  description = " The name of a KMS encrypted bucket that where the tile configuration is written"
  type        = string
}

variable "extra_users" {
  description = "extra users to add to all bosh managed vms"
  type = list(object({
    username       = string
    public_ssh_key = string
    sudo_priv      = bool
  }))
}