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

data "terraform_remote_state" "bootstrap_control_plane" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_control_plane"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "aws_route_tables" "es_private_route_tables" {
  vpc_id = data.terraform_remote_state.paperwork.outputs.es_vpc_id
  tags   = merge(var.global_vars["global_tags"], { "Type" = "PRIVATE" })
}

data "aws_route_table" "es_public_route_table" {
  vpc_id = data.terraform_remote_state.paperwork.outputs.es_vpc_id
  tags   = merge(var.global_vars["global_tags"], { "Type" = "PUBLIC" })
}

locals {
  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} enterprise services"
  modified_tags = merge(
    var.global_vars["global_tags"],
    {
      "Name"            = local.modified_name
      "MetricsKey"      = data.terraform_remote_state.paperwork.outputs.metrics_key,
      "foundation_name" = data.terraform_remote_state.paperwork.outputs.foundation_name
    },
  )

  es_vpc_id  = data.terraform_remote_state.paperwork.outputs.es_vpc_id
  pas_vpc_id = data.terraform_remote_state.paperwork.outputs.pas_vpc_id

  public_cidr_block  = cidrsubnet(data.aws_vpc.this_vpc.cidr_block, 1, 0)
  private_cidr_block = cidrsubnet(data.aws_vpc.this_vpc.cidr_block, 1, 1)
}

data "aws_vpc" "this_vpc" {
  id = local.es_vpc_id
}

module "tag_vpc" {
  source   = "../../modules/vpc_tagging"
  vpc_id   = local.es_vpc_id
  name     = "enterprise services"
  purpose  = "enterprise-services"
  env_name = local.env_name
}

data "aws_vpc" "pas_vpc" {
  id = local.pas_vpc_id
}

module "public_subnets" {
  source             = "../../modules/subnet_per_az"
  availability_zones = var.availability_zones
  vpc_id             = local.es_vpc_id
  cidr_block         = local.public_cidr_block
  tags = merge(
    local.modified_tags,
    {
      "Name" = "${local.modified_name}-public"
    },
  )
}

resource "aws_route_table_association" "public_route_table_assoc" {
  count          = length(var.availability_zones)
  subnet_id      = module.public_subnets.subnet_ids[count.index]
  route_table_id = data.aws_route_table.es_public_route_table.id
}

module "private_subnets" {
  source             = "../../modules/subnet_per_az"
  availability_zones = var.availability_zones
  vpc_id             = local.es_vpc_id
  cidr_block         = local.private_cidr_block
  tags = merge(
    local.modified_tags,
    {
      "Name" = "${local.modified_name}-private"
    },
  )
}

resource "aws_route_table_association" "private_route_table_assoc" {
  count          = length(var.availability_zones)
  subnet_id      = module.private_subnets.subnet_ids[count.index]
  route_table_id = tolist(data.aws_route_tables.es_private_route_tables.ids)[count.index]
}

variable "internetless" {
}

variable "remote_state_region" {
}

variable "remote_state_bucket" {
}

variable "global_vars" {
  type = any
}

variable "availability_zones" {
  type = list(string)
}


output "public_subnet_ids" {
  value = module.public_subnets.subnet_ids
}

output "public_subnet_cidrs" {
  value = module.public_subnets.subnet_cidr_blocks
}

output "private_subnet_ids" {
  value = module.private_subnets.subnet_ids
}

output "private_subnet_cidrs" {
  value = module.private_subnets.subnet_cidr_blocks
}
