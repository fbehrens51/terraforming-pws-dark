terraform {
  backend "s3" {
  }
}

provider "aws" {
}

module "providers" {
  source = "../../modules/dark_providers"
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

data "terraform_remote_state" "routes" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "routes"
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

locals {
  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} enterprise services"
  modified_tags = merge(
    var.global_vars["global_tags"],
    {
      "Name"       = local.modified_name
      "MetricsKey" = data.terraform_remote_state.paperwork.outputs.metrics_key,
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
  route_table_id = data.terraform_remote_state.routes.outputs.es_public_vpc_route_table_id
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
  route_table_id = data.terraform_remote_state.routes.outputs.es_private_vpc_route_table_ids[count.index]
}

data "template_cloudinit_config" "nat_user_data" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "clamav.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.amazon2_clamav_user_data
  }

  part {
    filename     = "node_exporter.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.node_exporter_user_data
  }

  part {
    filename     = "banner.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.custom_banner_user_data
  }

  part {
    filename     = "bot_user_accounts_user_data.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.bot_user_accounts_user_data
  }

  part {
    filename     = "tag_completion.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.completion_tag_user_data
  }
}

module "nat" {
  source                     = "../../modules/nat"
  ami_id                     = data.terraform_remote_state.paperwork.outputs.amzn_ami_id
  private_route_table_ids    = data.terraform_remote_state.routes.outputs.es_private_vpc_route_table_ids
  ingress_cidr_blocks        = [data.aws_vpc.this_vpc.cidr_block]
  metrics_ingress_cidr_block = data.aws_vpc.pas_vpc.cidr_block
  tags                       = { tags = local.modified_tags, instance_tags = var.global_vars["instance_tags"] }
  public_subnet_ids          = module.public_subnets.subnet_ids
  ssh_cidr_blocks            = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_cidrs
  internetless               = var.internetless
  instance_types             = data.terraform_remote_state.scaling-params.outputs.instance_types
  scale_vpc_key              = "enterprise-services"
  user_data                  = data.template_cloudinit_config.nat_user_data.rendered
  root_domain                = data.terraform_remote_state.paperwork.outputs.root_domain
  syslog_ca_cert             = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs
  bot_key_pem                = data.terraform_remote_state.paperwork.outputs.bot_private_key
  check_cloud_init           = data.terraform_remote_state.paperwork.outputs.check_cloud_init == "false" ? false : true

  public_bucket_name = data.terraform_remote_state.paperwork.outputs.public_bucket_name
  public_bucket_url  = data.terraform_remote_state.paperwork.outputs.public_bucket_url
  role_name          = data.terraform_remote_state.paperwork.outputs.instance_tagger_role_name
}

variable "internetless" {
}

variable "remote_state_region" {
}

variable "remote_state_bucket" {
}

variable "singleton_availability_zone" {
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

