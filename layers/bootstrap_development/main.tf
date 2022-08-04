variable "vpc_id" {
  type        = string
  description = "ID for Development VPC"
}

data "aws_route_table" "development_public_route_table" {
  vpc_id = var.vpc_id
  //  tags = merge(var.global_vars["global_tags"],{"Type"="PUBLIC"})
  tags = merge({}, {
    "Type" = "PUBLIC",
    "env"  = "Development"
  })
}


data "aws_vpc" "vpc" {
  id = var.vpc_id
}


locals {

  env_name = "Development"
  modified_tags = merge(
    {
    },
    {
      "Name" = local.env_name
    },
  )
}

module "tag_vpc" {
  source   = "../../modules/vpc_tagging"
  vpc_id   = var.vpc_id
  name     = "Development"
  purpose  = "Development"
  env_name = local.env_name
}

module "public_subnets" {
  source             = "../../modules/subnet_per_az"
  availability_zones = var.availability_zones
  vpc_id             = data.aws_vpc.vpc.id
  cidr_block         = data.aws_vpc.vpc.cidr_block
  tags = merge(
    local.modified_tags,
    {
      "Name" = "${local.env_name}-public"
    },
  )
}

resource "aws_route_table_association" "public_route_table_assoc" {
  count          = length(var.availability_zones)
  subnet_id      = module.public_subnets.subnet_ids[count.index]
  route_table_id = data.aws_route_table.development_public_route_table.id
}

variable "remote_state_region" {
}

variable "remote_state_bucket" {
}

variable "availability_zones" {
  type = list(string)
}

variable "internetless" {
}