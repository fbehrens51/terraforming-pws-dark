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

data "aws_vpc" "pas_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
}

data "aws_vpc" "cp_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.cp_vpc_id
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
      description = "Allow dns_udp/53 to all external hosts"
      port        = "53"
      protocol    = "udp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      description = "Allow dns_tcp/53 to all external hosts"
      port        = "53"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      //yum for postfix install
      description = "Allow http/80 to all external hosts for yum"
      port        = "80"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      //yum for clamav install (some repos are on 443)
      description = "Allow http/443 to all external hosts for yum"
      port        = "443"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      //syslog
      description = "Allow syslog/8090 to all external hosts"
      port        = "8090"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      // AWS SES smtp
      description = "Allow smtp/${var.smtp_relay_port} to all external hosts for smtp_relay"
      port        = var.smtp_relay_port
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  smtp_client_port = "25"

  postfix_ingress_rules = [
    {
      description = "Allow smtp/25 from all external hosts for smtp_relay"
      port        = local.smtp_client_port
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      description = "Allow ssh/22 from bastion_vpc"
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = data.terraform_remote_state.bastion.outputs.bastion_cidr_block
    },
    {
      description = "Allow ssh/22 from cp_vpc"
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = data.aws_vpc.cp_vpc.cidr_block
    },
    {
      // metrics endpoint for grafana
      description = "Allow node_exporter/9100 from pas_vpc"
      port        = "9100"
      protocol    = "tcp"
      cidr_blocks = data.aws_vpc.pas_vpc.cidr_block
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

