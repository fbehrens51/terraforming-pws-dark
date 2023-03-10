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

data "aws_route_table" "bastion_public_route_table"{
  vpc_id = data.terraform_remote_state.paperwork.outputs.bastion_vpc_id
  tags = merge(var.global_vars["global_tags"],{"Type"="PUBLIC"})
}

locals {
  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} bastion"
  modified_tags = merge(
    var.global_vars["global_tags"],
    {
      "Name" = local.modified_name
    },
  )
  instance_tags = merge(
    local.modified_tags,
    var.global_vars["instance_tags"],
    {
      "foundation_name" = data.terraform_remote_state.paperwork.outputs.foundation_name
      "job"             = "bastion"
    },
  )

  derived_route_table_id = var.route_table_id != null ? var.route_table_id : data.aws_route_table.bastion_public_route_table.id

  bot_user_data = <<DOC
#cloud-config
merge_how:
  - name: list
    settings: [append]
  - name: dict
    settings: [no_replace, recurse_list]

users:
  - name: bot
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: bosh_sshers
    shell: /bin/bash
    lock_passwd: true
    ssh_authorized_keys:
      - ${data.terraform_remote_state.paperwork.outputs.bot_public_key}
DOC
}

data "aws_route_table" "route_table" {
  route_table_id = local.derived_route_table_id
}

data "aws_vpc" "vpc" {
  id = data.aws_route_table.route_table.vpc_id
}

module "tag_vpc" {
  source = "../../modules/vpc_tagging"
  vpc_id = data.aws_route_table.route_table.vpc_id
  name = "bastion"
  purpose = "bastion"
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
      "Name" = "${local.modified_name}-public"
    },
  )
}

resource "aws_route_table_association" "public_route_table_assoc" {
  count          = length(var.availability_zones)
  subnet_id      = module.public_subnets.subnet_ids[count.index]
  route_table_id = local.derived_route_table_id
}

data "template_cloudinit_config" "bot_user_data" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "other.cfg"
    content_type = "text/cloud-config"
    content      = file("user_data.yml")
  }

  part {
    filename     = "bot_user"
    content_type = "text/cloud-config"
    content      = local.bot_user_data
  }

}

data "template_cloudinit_config" "user_data" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "other.cfg"
    content_type = "text/cloud-config"
    content      = file("user_data.yml")
  }
}


module "bootstrap" {
  source        = "../../modules/eni_per_subnet"
  ingress_rules = var.ingress_rules
  egress_rules  = var.egress_rules
  subnet_ids    = module.public_subnets.subnet_ids
  eni_count     = "1"
  create_eip    = var.internetless ? false : true
  tags          = local.modified_tags
}

module "bastion_host" {
  providers = {
    aws = aws.bastion
  }
  instance_count       = 1
  source               = "../../modules/launch"
  ignore_tag_changes   = true
  instance_types       = data.terraform_remote_state.scaling-params.outputs.instance_types
  scale_vpc_key        = "bastion"
  scale_service_key    = "bastion"
  ami_id               = local.ami_filter_provided ? data.aws_ami.bastion_ami.0.image_id : data.terraform_remote_state.paperwork.outputs.amzn_ami_id
  user_data            = var.add_bot_user_to_user_data ? data.template_cloudinit_config.bot_user_data.rendered : data.template_cloudinit_config.user_data.rendered
  eni_ids              = module.bootstrap.eni_ids
  tags                 = local.instance_tags
  iam_instance_profile = local.ami_filter_provided ? "" : data.terraform_remote_state.paperwork.outputs.instance_tagger_role_name
  operating_system     = var.bastion_operating_system_tag
}

variable "ami_filter" {
  type    = object({ owners = list(string), name_regex = string, filters = map(list(string)) })
  default = { owners = null, name_regex = null, filters = null }
}

locals {
  ami_filter_provided = var.ami_filter.owners == null ? false : true
}

data "aws_ami" "bastion_ami" {
  count       = local.ami_filter_provided ? 1 : 0
  owners      = var.ami_filter.owners
  name_regex  = var.ami_filter.name_regex
  most_recent = true
  dynamic "filter" {
    for_each = var.ami_filter.filters
    content {
      name   = filter.key
      values = filter.value
    }
  }
}

variable "remote_state_region" {
}

variable "remote_state_bucket" {
}

variable "availability_zones" {
  type = list(string)
}

variable "singleton_availability_zone" {
}

variable "internetless" {
}

variable "add_bot_user_to_user_data" {
  default = false
}

variable "ingress_rules" {
  type = list(object({ description = string, port = string, protocol = string, cidr_blocks = string }))
}

variable "egress_rules" {
  type = list(object({ description = string, port = string, protocol = string, cidr_blocks = string }))
}

variable "global_vars" {
  type = any
}

variable "route_table_id" {
  default = null
}

variable "bastion_operating_system_tag" {
  type    = string
  default = "varies"
}

module "sshconfig" {
  source         = "../../modules/ssh_config"
  foundation_name = data.terraform_remote_state.paperwork.outputs.foundation_name
  host_ips = zipmap(flatten(module.bastion_host.ssh_host_names), [element(concat(module.bootstrap.public_ips, [module.bootstrap.eni_ips[0]]), 0)])
  host_type = "bastion"
  secrets_bucket_name = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
}