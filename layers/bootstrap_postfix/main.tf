terraform {
  backend "s3" {
  }
}

data "terraform_remote_state" "enterprise-services" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "enterprise-services"
    region  = var.remote_state_region
    encrypt = true
  }
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

data "terraform_remote_state" "bastion" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bastion"
    region  = var.remote_state_region
    encrypt = true
  }
}

locals {
  env_name      = var.tags["Name"]
  modified_name = "${local.env_name} postfix"
  modified_tags = merge(
    var.tags,
    {
      "Name" = local.modified_name
    },
  )

  subnets = data.terraform_remote_state.enterprise-services.outputs.private_subnet_ids

  public_subnet = data.terraform_remote_state.enterprise-services.outputs.public_subnet_ids[0]

  //allow dns to reach out anywhere. This is needed for CNAME records to external DNS
  postfix_egress_rules = [
    {
      port        = "53"
      protocol    = "udp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port        = "53"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      //yum for postfix install
      port        = "80"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      //yum for clamav install (some repos are on 443)
      port        = "443"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      //splunk
      port        = "8090"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      // AWS SES smtp
      port        = var.smtp_relay_port
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  smtp_client_port = "25"

  postfix_ingress_rules = [
    {
      port        = local.smtp_client_port
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = data.terraform_remote_state.bastion.outputs.bastion_cidr_block
    },
  ]
}

resource "random_string" "smtp_client_password" {
  length  = "32"
  special = false
}

module "bootstrap" {
  source        = "../../modules/eni_per_subnet"
  ingress_rules = local.postfix_ingress_rules
  egress_rules  = local.postfix_egress_rules
  subnet_ids    = local.subnets
  eni_count     = "1"
  create_eip    = "false"
  tags          = local.modified_tags
}

module "domains" {
  source = "../../modules/domains"

  root_domain = data.terraform_remote_state.paperwork.outputs.root_domain
}

variable "remote_state_region" {
}

variable "remote_state_bucket" {
}

variable "smtp_relay_port" {
}

variable "tags" {
  type = map(string)
}

output "postfix_eni_ids" {
  value = module.bootstrap.eni_ids
}

output "postfix_eni_ips" {
  value = module.bootstrap.eni_ips
}

output "postfix_eip_ips" {
  value = module.bootstrap.public_ips
}

output "smtp_relay_port" {
  value = var.smtp_relay_port
}

output "smtp_client_port" {
  value = local.smtp_client_port
}

output "smtp_client_user" {
  value = "smtp_client"
}

output "smtp_client_password" {
  value     = random_string.smtp_client_password.result
  sensitive = true
}

