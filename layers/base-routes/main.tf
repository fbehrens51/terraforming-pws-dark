data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "paperwork"
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
  es_vpc_id      = data.terraform_remote_state.paperwork.outputs.es_vpc_id
  cp_vpc_id      = data.terraform_remote_state.paperwork.outputs.cp_vpc_id
  bastion_vpc_id = data.terraform_remote_state.paperwork.outputs.bastion_vpc_id

  es_s3_vpc_endpoint_id      = data.terraform_remote_state.paperwork.outputs.es_s3_vpc_endpoint_id
  cp_s3_vpc_endpoint_id      = data.terraform_remote_state.paperwork.outputs.cp_s3_vpc_endpoint_id
  bastion_s3_vpc_endpoint_id = data.terraform_remote_state.paperwork.outputs.bastion_s3_vpc_endpoint_id
}

module "bastion_vpc_route_tables" {
  source                 = "../../modules/vpc_route_tables"
  internetless           = var.internetless
  vpc_id                 = local.bastion_vpc_id
  s3_vpc_endpoint_id     = local.bastion_s3_vpc_endpoint_id
  availability_zones     = var.availability_zones
  enable_s3_vpc_endpoint = var.enable_bastion_s3_vpc_endpoint

  tags = merge(
    local.modified_tags,
    {
      Name = "${local.env_name_prefix} | BASTION"
    }
  )
}

module "es_vpc_route_tables" {
  source                 = "../../modules/vpc_route_tables"
  internetless           = var.internetless
  vpc_id                 = local.es_vpc_id
  s3_vpc_endpoint_id     = local.es_s3_vpc_endpoint_id
  availability_zones     = var.availability_zones
  enable_s3_vpc_endpoint = var.enable_es_s3_vpc_endpoint

  tags = merge(
    local.modified_tags,
    {
      Name = "${local.env_name_prefix} | ENT SVCS"
    }
  )

}

module "cp_vpc_route_tables" {
  source                 = "../../modules/vpc_route_tables"
  internetless           = var.internetless
  vpc_id                 = local.cp_vpc_id
  s3_vpc_endpoint_id     = local.cp_s3_vpc_endpoint_id
  availability_zones     = var.availability_zones
  enable_s3_vpc_endpoint = var.enable_cp_s3_vpc_endpoint

  tags = merge(
    local.modified_tags,
    {
      Name = "${local.env_name_prefix} | CP"
    }
  )
}

module "route_bastion_cp" {
  source           = "../../modules/routing"
  accepter_vpc_id  = local.bastion_vpc_id
  requester_vpc_id = local.cp_vpc_id
  accepter_route_table_ids = concat(
    module.bastion_vpc_route_tables.private_route_table_ids,
    [module.bastion_vpc_route_tables.public_route_table_id],
  )
  requester_route_table_ids = concat(
    module.cp_vpc_route_tables.private_route_table_ids,
    [module.cp_vpc_route_tables.public_route_table_id],
  )
  availability_zones = var.availability_zones
}

module "route_cp_es" {
  source           = "../../modules/routing"
  accepter_vpc_id  = local.cp_vpc_id
  requester_vpc_id = local.es_vpc_id
  accepter_route_table_ids = concat(
    module.cp_vpc_route_tables.private_route_table_ids,
    [module.cp_vpc_route_tables.public_route_table_id],
  )
  requester_route_table_ids = concat(
    module.es_vpc_route_tables.private_route_table_ids,
    [module.es_vpc_route_tables.public_route_table_id],
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

variable "enable_cp_s3_vpc_endpoint" {
  type    = bool
  default = true
}

variable "enable_es_s3_vpc_endpoint" {
  type    = bool
  default = true
}

variable "enable_bastion_s3_vpc_endpoint" {
  type    = bool
  default = true
}
