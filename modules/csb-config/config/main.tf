variable "availability_zones" {
  type = list(string)
}

variable "network_name" {
}

variable "scale" {
  type = map(map(string))
}

variable "csb_config" {
}

variable "secrets_bucket_name" {
}

variable "singleton_availability_zone" {
}

locals {
  csb_config = templatefile("${path.module}/csb_config.tpl", {
    network_name                = var.network_name
    scale                       = var.scale["p-csb"]
    singleton_availability_zone = var.singleton_availability_zone
    az_yaml                     = format("%#v", flatten([for zone in var.availability_zones : { "name" = zone }]))
  })
}

resource "aws_s3_bucket_object" "csb_template" {
  bucket  = var.secrets_bucket_name
  key     = var.csb_config
  content = local.csb_config
}
