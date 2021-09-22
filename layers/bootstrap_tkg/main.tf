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
    key     = "routes"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "aws_vpc" "vpc" {
  // 10.5.0.0/24
  id = data.terraform_remote_state.paperwork.outputs.tkg_vpc_id
}

locals {
  env_name            = var.global_vars.env_name
  modified_name       = "${local.env_name} tkg"
  modified_tags       = merge(var.global_vars["global_tags"])
  // 10.5.0.0/25
  public_subnet_cidr  = cidrsubnet(data.aws_vpc.vpc.cidr_block, 1, 0)
  // 10.5.0.128/25
  private_subnet_cidr = cidrsubnet(data.aws_vpc.vpc.cidr_block, 1, 1)
  // 10.5.0.224/27
  tkgjb_cidr_block      = cidrsubnet(local.private_subnet_cidr, 2, 3)
}

module "public_subnet" {
  source             = "../../modules/subnet_per_az"
  availability_zones = var.availability_zones
  vpc_id             = data.aws_vpc.vpc.id
  cidr_block         = local.public_subnet_cidr
  tags               = merge(
  local.modified_tags,
  {
    "Name"                                          = "${local.modified_name}-tkg",
    "kubernetes.io/role/elb"                        = 1,
    "kubernetes.io/cluster/${var.tkg_cluster_name}" = "shared"
  },
  )
}

module "private_subnet" {
  source             = "../../modules/subnet_per_az"
  availability_zones = var.availability_zones
  vpc_id             = data.aws_vpc.vpc.id
  cidr_block         = local.private_subnet_cidr
  tags               = merge(
  local.modified_tags,
  {
    "Name"                                          = "${local.modified_name}-tkg"
    "kubernetes.io/role/internal-elb"               = 1
    "kubernetes.io/cluster/${var.tkg_cluster_name}" = "shared"
  },
  )
}

resource "aws_route_table_association" "tkg_public_route_table_assoc" {
  count          = length(var.availability_zones)
  subnet_id      = module.public_subnet.subnet_ids[count.index]
  route_table_id = data.terraform_remote_state.routes.outputs.tkg_public_vpc_route_table_id
}

resource "aws_route_table_association" "tkg_private_route_table_assoc" {
  count          = length(var.availability_zones)
  subnet_id      = module.private_subnet.subnet_ids[count.index]
  route_table_id = data.terraform_remote_state.routes.outputs.tkg_private_vpc_route_table_ids[count.index]
}
