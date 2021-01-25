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

data "terraform_remote_state" "routes" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "routes"
    region  = var.remote_state_region
    encrypt = true
  }
}

locals {
  env_name      = var.tags["Name"]
  modified_name = "${local.env_name} bastion"
  modified_tags = merge(
    var.tags,
    {
      "Name" = local.modified_name
    },
  )
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
  route_table_id = data.terraform_remote_state.routes.outputs.bastion_public_vpc_route_table_id
}

data "aws_vpc" "vpc" {
  id = data.aws_route_table.route_table.vpc_id
}

module "bootstrap_bastion" {
  source            = "../../modules/single_use_subnet"
  availability_zone = var.singleton_availability_zone
  cidr_block        = data.aws_vpc.vpc.cidr_block
  route_table_id    = data.terraform_remote_state.routes.outputs.bastion_public_vpc_route_table_id
  ingress_rules     = var.ingress_rules
  egress_rules      = var.egress_rules
  tags              = local.modified_tags
  create_eip        = ! var.internetless
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

module "amazon_ami" {
  source = "../../modules/amis/amazon_hvm_ami"
}

module "bastion_host" {
  instance_count     = "1"
  source             = "../../modules/launch"
  ignore_tag_changes = true
  ami_id             = var.ami_id == "" ? module.amazon_ami.id : var.ami_id
  user_data          = var.add_bot_user_to_user_data ? data.template_cloudinit_config.bot_user_data.rendered : data.template_cloudinit_config.user_data.rendered
  eni_ids            = [module.bootstrap_bastion.eni_id]

  tags = local.modified_tags
}

variable "ami_id" {
  description = "The AMI id for the bastion host.  If left blank the most recent `amzn-ami-hvm` AMI will be used."
  default     = ""
}

variable "remote_state_region" {
}

variable "remote_state_bucket" {
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

variable "tags" {
  type = map(string)
}

