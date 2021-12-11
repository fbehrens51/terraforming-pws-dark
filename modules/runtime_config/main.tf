variable "ipsec_log_level" {
}

variable "ipsec_subnet_cidrs" {
  type = list(string)
}

variable "no_ipsec_subnet_cidrs" {
  type = list(string)
}

variable "custom_ssh_banner" {
  type        = string
  description = "Custom SSH Banner to be used on launched VMs"
}

variable "s3_endpoint" {
}

variable "region" {
}

variable "vpc_dns" {
}

variable "runtime_config" {
}

locals {
  runtime_config_file_glob    = "pws-dark-runtime-config*.pivotal"
  runtime_config_product_slug = "pws-dark-runtime-config-tile"
  vpc_dns_subnet              = "${var.vpc_dns}/32"
}

resource "aws_s3_bucket_object" "runtime_config_template" {
  bucket = var.secrets_bucket_name
  key    = var.runtime_config
  content = templatefile("${path.module}/runtime_config_template.tpl", {
    runtime_config     = var.runtime_config
    ipsec_log_level    = var.ipsec_log_level
    ipsec_subnet_cidrs = join(",", var.ipsec_subnet_cidrs)
    no_ipsec_subnet_cidrs = join(
      ",",
      concat(var.no_ipsec_subnet_cidrs, [local.vpc_dns_subnet]),
    )
    ssh_banner  = var.custom_ssh_banner
  })
}

variable "secrets_bucket_name" {
  description = " The name of a KMS encrypted bucket that where the tile configuration is written"
  type        = string
}


