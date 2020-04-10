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

module "splunk_ports" {
  source = "../../modules/splunk_ports"
}

locals {
  env_name      = var.tags["Name"]
  modified_name = "${local.env_name} bootstrap bind"
  modified_tags = merge(
    var.tags,
    {
      "Name" = local.modified_name
    },
  )

  //allow dns to reach out anywhere. This is needed for CNAME records to external DNS
  bind_egress_rules = [
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
      //yum for bind install
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
      //splunk syslog
      port        = module.splunk_ports.splunk_tcp_port
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  bind_ingress_rules = [
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
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = data.aws_vpc.cp_vpc.cidr_block
    },
    {
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = data.terraform_remote_state.bastion.outputs.bastion_cidr_block
    },
    {
      // metrics endpoint for grafana
      port        = "9100"
      protocol    = "tcp"
      cidr_blocks = data.aws_vpc.pas_vpc.cidr_block
    },
  ]
}

data "aws_vpc" "cp_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.cp_vpc_id
}

data "aws_vpc" "pas_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
}

module "bootstrap" {
  source        = "../../modules/eni_per_subnet"
  ingress_rules = local.bind_ingress_rules
  egress_rules  = local.bind_egress_rules
  subnet_ids    = data.terraform_remote_state.enterprise-services.outputs.public_subnet_ids
  eni_count     = "3"
  create_eip    = ! var.internetless
  tags          = local.modified_tags
}

data "aws_network_interface" "master_eni" {
  id = module.bootstrap.eni_ids[0]
}

variable "remote_state_region" {
}

variable "remote_state_bucket" {
}

variable "internetless" {
}

variable "tags" {
  type = map(string)
}

output "bind_eni_ids" {
  value = module.bootstrap.eni_ids
}

output "bind_eni_ips" {
  value = module.bootstrap.eni_ips
}

output "bind_eip_ips" {
  value = module.bootstrap.public_ips
}

