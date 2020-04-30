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

data "terraform_remote_state" "bastion" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bastion"
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

data "terraform_remote_state" "encrypt_amis" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "encrypt_amis"
    region  = var.remote_state_region
    encrypt = true
  }
}

locals {
  env_name      = var.tags["Name"]
  modified_name = "${local.env_name} enterprise services"
  modified_tags = merge(
    var.tags,
    {
      "Name" = local.modified_name
    },
  )
  es_vpc_id  = data.terraform_remote_state.paperwork.outputs.es_vpc_id
  pas_vpc_id = data.terraform_remote_state.paperwork.outputs.pas_vpc_id

  splunk_volume_tag = "${var.env_name}-SPLUNK_DATA"

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

resource "aws_security_group" "alb" {
  name   = "${var.env_name}-alb"
  vpc_id = local.es_vpc_id
  tags   = local.modified_tags
}

resource "aws_security_group_rule" "alb_ingress" {
  security_group_id = aws_security_group.alb.id

  protocol  = "tcp"
  from_port = 443
  to_port   = 443
  type      = "ingress"

  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_ingress_80" {
  security_group_id = aws_security_group.alb.id

  protocol  = "tcp"
  from_port = 80
  to_port   = 80
  type      = "ingress"

  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_egress" {
  security_group_id = aws_security_group.alb.id

  protocol                 = "tcp"
  from_port                = 0
  to_port                  = 65535
  type                     = "egress"
  source_security_group_id = aws_security_group.alb_targets.id
}

resource "aws_security_group" "alb_targets" {
  name   = "${var.env_name}-alb-targets"
  vpc_id = local.es_vpc_id
  tags   = local.modified_tags
}

resource "aws_security_group_rule" "alb_to_targets" {
  security_group_id = aws_security_group.alb_targets.id

  protocol                 = "tcp"
  from_port                = 0
  to_port                  = 65535
  type                     = "ingress"
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_lb" "shared_alb" {
  name                             = "${replace(var.env_name, " ", "-")}-internal"
  internal                         = var.internetless
  load_balancer_type               = "application"
  security_groups                  = [aws_security_group.alb.id]
  subnets                          = module.public_subnets.subnet_ids
  enable_cross_zone_load_balancing = true

  tags = local.modified_tags
}


resource "aws_iam_server_certificate" "default" {
  name             = "${replace(var.env_name, " ", "-")}-default"
  private_key      = data.terraform_remote_state.paperwork.outputs.router_server_key
  certificate_body = data.terraform_remote_state.paperwork.outputs.router_server_cert
}

resource "aws_lb_listener" "shared" {
  load_balancer_arn = aws_lb.shared_alb.arn

  port            = 443
  protocol        = "HTTPS"
  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = aws_iam_server_certificate.default.arn


  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "200"
    }
  }
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
    filename     = "user_accounts_user_data.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.user_accounts_user_data
  }
}

module "nat" {
  source                     = "../../modules/nat"
  ami_id                     = data.terraform_remote_state.encrypt_amis.outputs.encrypted_amazon2_ami_id
  private_route_table_ids    = data.terraform_remote_state.routes.outputs.es_private_vpc_route_table_ids
  ingress_cidr_blocks        = [data.aws_vpc.this_vpc.cidr_block]
  metrics_ingress_cidr_block = data.aws_vpc.pas_vpc.cidr_block
  tags                       = local.modified_tags
  public_subnet_ids          = module.public_subnets.subnet_ids
  bastion_private_ip         = "${data.terraform_remote_state.bastion.outputs.bastion_private_ip}/32"
  internetless               = var.internetless
  instance_type              = var.nat_instance_type
  user_data                  = data.template_cloudinit_config.nat_user_data.rendered
  root_domain                = data.terraform_remote_state.paperwork.outputs.root_domain
  splunk_syslog_ca_cert      = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs

  public_bucket_name = data.terraform_remote_state.paperwork.outputs.public_bucket_name
  public_bucket_url  = data.terraform_remote_state.paperwork.outputs.public_bucket_url
}

variable "nat_instance_type" {
  default = "t2.small"
}

variable "env_name" {
}

variable "internetless" {
}

variable "remote_state_region" {
}

variable "remote_state_bucket" {
}

variable "singleton_availability_zone" {
}

variable "tags" {
  type = map(string)
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

output "shared_alb_dns_name" {
  value = aws_lb.shared_alb.dns_name
}

output "shared_alb_listener_arn" {
  value = aws_lb_listener.shared.arn
}

output "shared_alb_target_sg" {
  value = aws_security_group.alb_targets.id
}
