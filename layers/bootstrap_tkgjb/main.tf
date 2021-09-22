data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "paperwork"
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

data "terraform_remote_state" "bootstrap_tkg" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_tkg"
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

data "aws_vpc" "cp_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.cp_vpc_id
}

data "aws_vpc" "tkg_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.tkg_vpc_id
}

data "aws_vpc" "bastion_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.bastion_vpc_id
}

locals {
  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} control plane"
  modified_tags = merge(
  var.global_vars["global_tags"],
  {
    "Name"            = local.modified_name
    "MetricsKey"      = data.terraform_remote_state.paperwork.outputs.metrics_key,
    "foundation_name" = data.terraform_remote_state.paperwork.outputs.foundation_name
  },
  )

  tkgjb_ingress_rules = concat(var.tkgjb_ingress_rules,
  [
    {
      // metrics endpoint for grafana
      description = "Allow grafana_metrics/9100 from pas_vpc"
      port        = "9100"
      protocol    = "tcp"
      cidr_blocks = data.aws_vpc.tkg_vpc.cidr_block
    },
    {
      description = "Allow ssh from cp"
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = data.aws_vpc.cp_vpc.cidr_block
    },
    {
      description = "Allow ssh from bastion"
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = data.aws_vpc.bastion_vpc.cidr_block
    },
  ]
  )
}

//10.1.0.128/27 == [10.1.0.129, 10.1.0.158] (32)
//The CIDR '10.1.0.128/27' conflicts with another subnet
//module "tkgjb_subnet" {
//  source             = "../../modules/subnet_per_az"
//  availability_zones = [var.singleton_availability_zone]
//  vpc_id             = data.aws_vpc.cp_vpc.id
//  cidr_block         = data.terraform_remote_state.bootstrap_control_plane.outputs.tkgjb_cidr_block
//  tags = merge(
//  local.modified_tags,
//  {
//    "Name" = "${local.modified_name}-tkgjb"
//  },
//  )
//}

module "tkgjb_subnet" {
  source             = "../../modules/subnet_per_az"
  availability_zones = [var.singleton_availability_zone]
  vpc_id             = data.aws_vpc.tkg_vpc.id
  cidr_block         = data.terraform_remote_state.bootstrap_tkg.outputs.tkgjb_cidr_block
  tags = merge(
    local.modified_tags,
    {
      "Name" = "${local.modified_name}-tkgjb"
    },
  )
}

//resource "aws_route_table_association" "tkgjb_route_table_assoc" {
//  count          = "1"
//  subnet_id      = module.tkgjb_subnet.subnet_ids[count.index]
//  route_table_id = data.terraform_remote_state.routes.outputs.cp_private_vpc_route_table_ids[count.index]
//}

resource "aws_route_table_association" "tkgjb_route_table_assoc" {
  count          = "1"
  subnet_id      = module.tkgjb_subnet.subnet_ids[count.index]
  route_table_id = data.terraform_remote_state.routes.outputs.tkg_private_vpc_route_table_ids[count.index]
}

module "tkgjb_bootstrap" {
  source        = "../../modules/eni_per_subnet"
  ingress_rules = local.tkgjb_ingress_rules
  egress_rules  = var.tkgjb_egress_rules
  subnet_ids    = module.tkgjb_subnet.subnet_ids
  eni_count     = "1"
  create_eip    = "false"
  tags          = local.modified_tags
}

//module "tkgjb_bootstrap" {
//  source        = "../../modules/eni_per_subnet"
//  ingress_rules = local.tkgjb_ingress_rules
//  egress_rules  = var.tkgjb_egress_rules
//  subnet_ids    = module.tkgjb_subnet.subnet_ids
//  eni_count     = "1"
//  create_eip    = "false"
//  tags          = local.modified_tags
//}
