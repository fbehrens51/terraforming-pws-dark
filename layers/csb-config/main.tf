variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "availability_zones" {
  type = list(string)
}

variable "singleton_availability_zone" {
}

variable "csb_config" {
  default = "pas/csb_tile_config.yml"
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

data "terraform_remote_state" "scaling-params" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "scaling-params"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "aws_vpc" "pas_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
}

locals {
  secrets_bucket_name = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
}

module "csb_config" {
  source                      = "../../modules/csb-config/config"
  scale                       = data.terraform_remote_state.scaling-params.outputs.instance_types
  secrets_bucket_name         = local.secrets_bucket_name
  csb_config                  = var.csb_config
  network_name                = data.terraform_remote_state.paperwork.outputs.pas_network_name
  availability_zones          = var.availability_zones
  singleton_availability_zone = var.singleton_availability_zone
}

resource "aws_s3_bucket_object" "allowed-cidr" {
  bucket       = local.secrets_bucket_name
  content_type = "application/json"
  key          = "allowed-cidrs/platform-csb"
  content      = jsonencode({ "description" : "Allow csb access to foundation credhub and uaa", "destination" : data.aws_vpc.pas_vpc.cidr_block, "ports" : "8844,8443", "protocol" : "tcp" })
}
