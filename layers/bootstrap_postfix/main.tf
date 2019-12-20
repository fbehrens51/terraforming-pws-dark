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

data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "paperwork"
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

data "terraform_remote_state" "bind" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "bind"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_bind" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "bootstrap_bind"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

locals {
  env_name      = "${var.tags["Name"]}"
  modified_name = "${local.env_name} postfix"
  modified_tags = "${merge(var.tags, map("Name", "${local.modified_name}"))}"

  subnets = "${data.terraform_remote_state.enterprise-services.private_subnet_ids}"

  dns_zone_name    = "${data.terraform_remote_state.paperwork.root_domain}"
  master_dns_ip    = "${data.terraform_remote_state.bind.master_public_ip}"
  bind_rndc_secret = "${data.terraform_remote_state.bootstrap_bind.bind_rndc_secret}"
  public_subnet    = "${data.terraform_remote_state.enterprise-services.public_subnet_ids[0]}"

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
      // AWS SES smtp
      port        = "${var.smtp_relay_port}"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  smtp_client_port = "25"

  postfix_ingress_rules = [
    {
      port        = "${local.smtp_client_port}"
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

resource "random_string" "smtp_client_password" {
  length  = "32"
  special = false
}

module "bootstrap" {
  source        = "../../modules/eni_per_subnet"
  ingress_rules = "${local.postfix_ingress_rules}"
  egress_rules  = "${local.postfix_egress_rules}"
  subnet_ids    = "${local.subnets}"
  eni_count     = "1"
  create_eip    = "false"
  tags          = "${local.modified_tags}"
}

module "domains" {
  source = "../../modules/domains"

  root_domain = "${data.terraform_remote_state.paperwork.root_domain}"
}

provider "dns" {
  update {
    server        = "${local.master_dns_ip}"
    key_name      = "rndc-key."
    key_algorithm = "hmac-md5"
    key_secret    = "${local.bind_rndc_secret}"
  }
}

resource "dns_a_record_set" "postfix_a_record" {
  zone      = "${local.dns_zone_name}."
  name      = "${module.domains.smtp_subdomain}"
  addresses = ["${module.bootstrap.eni_ips}"]
  ttl       = 300
}

variable "remote_state_region" {}
variable "remote_state_bucket" {}
variable "smtp_relay_port" {}

variable "tags" {
  type = "map"
}

output "postfix_eni_ids" {
  value = "${module.bootstrap.eni_ids}"
}

output "postfix_eni_ips" {
  value = "${module.bootstrap.eni_ips}"
}

output "postfix_eip_ips" {
  value = "${module.bootstrap.public_ips}"
}

output "smtp_relay_port" {
  value = "${var.smtp_relay_port}"
}

output "smtp_client_port" {
  value = "${local.smtp_client_port}"
}

output "smtp_client_user" {
  value = "smtp_client"
}

output "smtp_client_password" {
  value     = "${random_string.smtp_client_password.result}"
  sensitive = true
}
