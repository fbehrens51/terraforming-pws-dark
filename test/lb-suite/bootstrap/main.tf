variable "global_vars" {
  type = any
}
variable "availability_zones" {
  type = list(string)
}
variable "vpc_id" {
  type = string
}

data aws_vpc "this_vpc"{
  id = var.vpc_id
}

locals {
  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} TF validation"
  modified_tags = merge(
    var.global_vars["global_tags"],
    {
      "Name" = local.modified_name
    },
  )

  public_cidr_block  = cidrsubnet(data.aws_vpc.this_vpc.cidr_block, 1, 0)
  private_cidr_block = cidrsubnet(data.aws_vpc.this_vpc.cidr_block, 1, 1)
}


module "public_subnets" {
  source             = "../../../modules/subnet_per_az"
  availability_zones = var.availability_zones
  vpc_id             = var.vpc_id
  cidr_block         = local.public_cidr_block
  tags = merge(
    local.modified_tags,
    {
      "Name" = "${local.modified_name}-public"
      "Type" = "PUBLIC"
    },
  )
}

module "private_subnets" {
  source             = "../../../modules/subnet_per_az"
  availability_zones = var.availability_zones
  vpc_id             = var.vpc_id
  cidr_block         = local.private_cidr_block
  tags = merge(
    local.modified_tags,
    {
      "Name" = "${local.modified_name}-private"
      "Type" = "PRIVATE"
    },
  )
}
