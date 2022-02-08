data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "paperwork"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "routes" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "base-routes"
    region  = var.remote_state_region
    encrypt = true
  }
}

locals {
  env_name_prefix = var.global_vars.name_prefix
  modified_tags = merge(
    var.global_vars["global_tags"],
    {
      "foundation_name" = data.terraform_remote_state.paperwork.outputs.foundation_name
    },
  )
  pas_vpc_id     = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
  es_vpc_id      = data.terraform_remote_state.paperwork.outputs.es_vpc_id
  cp_vpc_id      = data.terraform_remote_state.paperwork.outputs.cp_vpc_id
  bastion_vpc_id = data.terraform_remote_state.paperwork.outputs.bastion_vpc_id

  pas_s3_vpc_endpoint_id = data.terraform_remote_state.paperwork.outputs.pas_s3_vpc_endpoint_id
}

module "pas_vpc_route_tables" {
  source                 = "../../modules/vpc_route_tables"
  internetless           = var.internetless
  vpc_id                 = local.pas_vpc_id
  s3_vpc_endpoint_id     = local.pas_s3_vpc_endpoint_id
  availability_zones     = var.availability_zones
  enable_s3_vpc_endpoint = var.enable_pas_s3_vpc_endpoint

  tags = merge(
    local.modified_tags,
    {
      Name = "${local.env_name_prefix} | PAS"
    }
  )
}

module "route_cp_pas" {
  source           = "../../modules/routing"
  accepter_vpc_id  = local.cp_vpc_id
  requester_vpc_id = local.pas_vpc_id
  accepter_route_table_ids = concat(
    data.terraform_remote_state.routes.outputs.cp_private_vpc_route_table_ids,
    [data.terraform_remote_state.routes.outputs.cp_public_vpc_route_table_id],
  )
  requester_route_table_ids = concat(
    module.pas_vpc_route_tables.private_route_table_ids,
    [module.pas_vpc_route_tables.public_route_table_id],
  )
  availability_zones = var.availability_zones
}

module "route_pas_es" {
  source           = "../../modules/routing"
  accepter_vpc_id  = local.pas_vpc_id
  requester_vpc_id = local.es_vpc_id
  accepter_route_table_ids = concat(
    module.pas_vpc_route_tables.private_route_table_ids,
    [module.pas_vpc_route_tables.public_route_table_id],
  )
  requester_route_table_ids = concat(
    data.terraform_remote_state.routes.outputs.es_private_vpc_route_table_ids,
    [data.terraform_remote_state.routes.outputs.es_public_vpc_route_table_id],
  )
  availability_zones = var.availability_zones
}

variable "remote_state_region" {
}

variable "remote_state_bucket" {
}

variable "internetless" {
  type = bool
}

variable "global_vars" {
  type = any
}

variable "availability_zones" {
  type = list(string)
}


variable "enable_pas_s3_vpc_endpoint" {
  type    = bool
  default = true
}