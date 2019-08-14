terraform {
  backend "s3" {}
}

data "terraform_remote_state" "enterprise-services" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "enterprise-services"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

data "terraform_remote_state" "bastion" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "bastion"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

locals {
  env_name      = "${var.tags["Name"]}"
  modified_name = "${local.env_name} bootstrap bind"
  modified_tags = "${merge(var.tags, map("Name", "${local.modified_name}"))}"

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
      cidr_blocks = "${data.terraform_remote_state.bastion.bastion_cidr_block}"
    },
  ]
}

module "bootstrap" {
  source        = "../../modules/eni_per_subnet"
  ingress_rules = "${local.bind_ingress_rules}"
  egress_rules  = "${local.bind_egress_rules}"
  subnet_ids    = "${data.terraform_remote_state.enterprise-services.public_subnet_ids}"
  eni_count     = "3"
  create_eip    = "${!var.internetless}"
  tags          = "${local.modified_tags}"
}

variable "remote_state_region" {}
variable "remote_state_bucket" {}
variable "internetless" {}

variable "tags" {
  type = "map"
}

output "bind_eni_ids" {
  value = "${module.bootstrap.eni_ids}"
}

output "bind_eni_ips" {
  value = "${module.bootstrap.eni_ips}"
}

output "bind_eip_ips" {
  value = "${module.bootstrap.public_ips}"
}