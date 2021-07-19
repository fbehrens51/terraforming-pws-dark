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

module "syslog_ports" {
  source = "../../modules/syslog_ports"
}

locals {
  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} bootstrap bind"
  modified_tags = merge(
    var.global_vars["global_tags"],
    {
      "Name" = local.modified_name
    },
  )

  //allow dns to reach out anywhere. This is needed for CNAME records to external DNS
  bind_egress_rules = [
    {
      description = "Allow dns_udp/53 egress to all external hosts"
      port        = "53"
      protocol    = "udp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      description = "Allow dns_tcp/53 egress to all external hosts"
      port        = "53"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      //yum for bind install
      description = "Allow http/80 egress to all external hosts for yum"
      port        = "80"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      //yum for clamav install (some repos are on 443)
      description = "Allow https/443 to all external hosts for clamav install"
      port        = "443"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      //syslog
      description = "Allow all syslog/${module.syslog_ports.syslog_port} to all external hosts for syslog"
      port        = module.syslog_ports.syslog_port
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      //smtp
      description = "Allow all smtp/25 to postfix"
      port        = 25
      protocol    = "tcp"
      //TODO: add variable for postfix subnet
      cidr_blocks = data.aws_vpc.es_vpc.cidr_block
    },
  ]

  bind_ingress_rules = [
    {
      description = "Allow dns_udp/53 egress from all external hosts"
      port        = "53"
      protocol    = "udp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      description = "Allow dns_tcp/53 egress from all external hosts"
      port        = "53"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
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

data "aws_vpc" "es_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.es_vpc_id
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

variable "global_vars" {
  type = any
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

