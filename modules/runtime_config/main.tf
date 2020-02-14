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

variable "mirror_bucket_name" {
}

variable "s3_endpoint" {
}

variable "region" {
}

variable "vpc_dns" {
}

locals {
  runtime_config_file_glob    = "pws-dark-runtime-config*.pivotal"
  runtime_config_product_slug = "pws-dark-runtime-config-tile"
  vpc_dns_subnet              = "${var.vpc_dns}/32"
}

data "template_file" "runtime_config_template" {
  template = file("${path.module}/runtime_config_template.tpl")

  vars = {
    ipsec_log_level    = var.ipsec_log_level
    ipsec_subnet_cidrs = join(",", var.ipsec_subnet_cidrs)
    no_ipsec_subnet_cidrs = join(
      ",",
      concat(var.no_ipsec_subnet_cidrs, [local.vpc_dns_subnet]),
    )
    ssh_banner            = var.custom_ssh_banner
    extra_user_name       = var.extra_user_name
    extra_user_public_key = var.extra_user_public_key
    extra_user_sudo       = var.extra_user_sudo
  }
}

output "runtime_config_template" {
  value     = data.template_file.runtime_config_template.rendered
  sensitive = true
}

variable "extra_user_name" {
  description = "The username of the extra user that will be added to all bosh managed VMs"
  default     = ""
}

variable "extra_user_public_key" {
  description = "The SSH public key of the extra user that will be added to all bosh managed VMs"
  default     = ""
}

variable "extra_user_sudo" {
  description = "Whether to grant sudo acces to the extra user"
  default     = false
}

