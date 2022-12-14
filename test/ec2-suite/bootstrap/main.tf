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

#resource "aws_route_table_association" "public_route_table_assoc" {
#  count          = length(var.availability_zones)
#  subnet_id      = module.public_subnets.subnet_ids[count.index]
#  route_table_id = data.aws_route_table.es_public_route_table.id
#}

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

#resource "aws_route_table_association" "private_route_table_assoc" {
#  count          = length(var.availability_zones)
#  subnet_id      = module.private_subnets.subnet_ids[count.index]
#  route_table_id = tolist(data.aws_route_tables.es_private_route_tables.ids)[count.index]
#}