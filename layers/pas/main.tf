provider "aws" {
}

module "providers" {
  source = "../../modules/dark_providers"
}

terraform {
  backend "s3" {
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

data "terraform_remote_state" "routes" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "routes"
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

data "terraform_remote_state" "encrypt_amis" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "encrypt_amis"
    region  = var.remote_state_region
    encrypt = true
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

module "infra" {
  source = "../../modules/infra"

  nat_ami_id = data.terraform_remote_state.encrypt_amis.outputs.encrypted_amazon2_ami_id

  env_name                      = var.env_name
  availability_zones            = var.availability_zones
  internetless                  = var.internetless
  dns_suffix                    = ""
  tags                          = local.modified_tags
  use_route53                   = false
  vpc_id                        = local.vpc_id
  public_route_table_id         = local.route_table_id
  bastion_private_ip            = data.terraform_remote_state.bastion.outputs.bastion_private_ip
  private_route_table_ids       = data.terraform_remote_state.routes.outputs.pas_private_vpc_route_table_ids
  nat_instance_type             = var.nat_instance_type
  root_domain                   = data.terraform_remote_state.paperwork.outputs.root_domain
  splunk_syslog_ca_cert         = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs
  ops_manager_security_group_id = module.ops_manager.security_group_id
  elb_security_group_id         = module.pas_elb.security_group_id

  user_data = data.template_cloudinit_config.nat_user_data.rendered

  public_bucket_name = data.terraform_remote_state.paperwork.outputs.public_bucket_name
  public_bucket_url  = data.terraform_remote_state.paperwork.outputs.public_bucket_url
}

module "om_key_pair" {
  source   = "../../modules/key_pair"
  key_name = local.om_key_name
}

module "pas" {
  source                    = "../../modules/pas"
  availability_zones        = var.availability_zones
  dns_suffix                = ""
  env_name                  = var.env_name
  public_subnet_ids         = module.infra.public_subnet_ids
  route_table_ids           = data.terraform_remote_state.routes.outputs.pas_private_vpc_route_table_ids
  tags                      = local.modified_tags
  vpc_id                    = local.vpc_id
  zone_id                   = module.infra.zone_id
  bucket_suffix             = local.bucket_suffix
  create_backup_pas_buckets = false
  create_versioned_pas_buckets = true
  s3_logs_bucket            = data.terraform_remote_state.paperwork.outputs.s3_logs_bucket
}

module "rds" {
  source = "../../modules/rds/instance"

  rds_db_username    = var.rds_db_username
  rds_instance_class = var.rds_instance_class

  engine = "mariadb"

  # RDS decided to upgrade the patch version automatically from 10.1.31 to
  # 10.1.34, which makes terraform see this as a change.  Use a prefix version
  # to prevent this from happening.
  engine_version = "10.1"

  db_port = 3306

  env_name = var.env_name
  vpc_id   = module.infra.vpc_id
  tags     = local.modified_tags

  subnet_group_name = module.rds_subnet_group.subnet_group_name

  kms_key_id = data.terraform_remote_state.paperwork.outputs.kms_key_arn
}

module "rds_subnet_group" {
  source = "../../modules/rds/subnet_group"

  env_name           = var.env_name
  availability_zones = var.availability_zones
  vpc_id             = module.infra.vpc_id
  cidr_block         = module.calculated_subnets.rds_cidr
  tags               = local.modified_tags
}

module "pas_elb" {
  source            = "../../modules/elb/create"
  env_name          = var.env_name
  internetless      = var.internetless
  public_subnet_ids = module.infra.public_subnet_ids
  tags              = local.modified_tags
  vpc_id            = local.vpc_id
  egress_cidrs      = module.pas.pas_subnet_cidrs
  short_name        = "pas"
  health_check      = "HTTP:8080/health" # Gorouter healthcheck
}

data "aws_vpc" "cp_vpc" {
  id = local.cp_vpc_id
}

data "aws_vpc" "pas_vpc" {
  id = local.vpc_id
}

data "aws_vpc" "bastion_vpc" {
  id = local.bastion_vpc_id
}

module "ops_manager" {
  source = "../../modules/ops_manager/infra"

  bucket_suffix = local.bucket_suffix
  env_name      = var.env_name
  om_eip        = ! var.internetless
  private       = false
  subnet_id     = module.infra.public_subnet_ids[0]
  tags          = local.modified_tags
  vpc_id        = local.vpc_id
  ingress_rules = local.ingress_rules
  s3_logs_bucket = local.s3_logs_bucket
}

resource "random_integer" "bucket" {
  min = 1
  max = 100000
}

variable "nat_instance_type" {
  default = "t2.small"
}

variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "rds_db_username" {
}

variable "rds_instance_class" {
}

variable "env_name" {
}

variable "availability_zones" {
  type = list(string)
}

variable "internetless" {
}

variable "tags" {
  type = map(string)
}

locals {
  env_name      = var.tags["Name"]
  modified_name = "${local.env_name} pas"
  modified_tags = merge(
    var.tags,
    {
      "Name" = local.modified_name
    },
  )
  cp_vpc_id      = data.terraform_remote_state.paperwork.outputs.cp_vpc_id
  bastion_vpc_id = data.terraform_remote_state.paperwork.outputs.bastion_vpc_id
  vpc_id         = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
  route_table_id = data.terraform_remote_state.routes.outputs.pas_public_vpc_route_table_id
  bucket_suffix  = random_integer.bucket.result
  root_domain    = data.terraform_remote_state.paperwork.outputs.root_domain
  om_key_name    = "${var.env_name}-om"
  s3_logs_bucket = data.terraform_remote_state.paperwork.outputs.s3_logs_bucket

  ingress_rules = [
    {
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = "${data.aws_vpc.cp_vpc.cidr_block},${data.aws_vpc.bastion_vpc.cidr_block}"
    },
    {
      port        = "443"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

module "calculated_subnets" {
  source   = "../../modules/calculate_subnets"
  vpc_cidr = data.aws_vpc.pas_vpc.cidr_block
}

output "om_private_key_pem" {
  value     = module.om_key_pair.private_key_pem
  sensitive = true
}

output "public_subnet_ids" {
  value = module.infra.public_subnet_ids
}

output "pas_elb_dns_name" {
  value = module.pas_elb.dns_name
}

output "pas_elb_id" {
  value = module.pas_elb.my_elb_id
}

output "rds_address" {
  value = module.rds.rds_address
}

output "rds_password" {
  value     = module.rds.rds_password
  sensitive = true
}

output "rds_port" {
  value = module.rds.rds_port
}

output "rds_username" {
  value = module.rds.rds_username
}

output "rds_subnet_group_name" {
  value = module.rds_subnet_group.subnet_group_name
}

output "ops_manager_bucket" {
  value = module.ops_manager.bucket
}

output "pas_buildpacks_bucket" {
  value = module.pas.pas_buildpacks_bucket
}

output "pas_droplets_bucket" {
  value = module.pas.pas_droplets_bucket
}

output "pas_packages_bucket" {
  value = module.pas.pas_packages_bucket
}

output "pas_resources_bucket" {
  value = module.pas.pas_resources_bucket
}

output "pas_buildpacks_backup_bucket" {
  value = module.pas.pas_buildpacks_backup_bucket
}

output "pas_droplets_backup_bucket" {
  value = module.pas.pas_droplets_backup_bucket
}

output "pas_packages_backup_bucket" {
  value = module.pas.pas_packages_backup_bucket
}

output "pas_resources_backup_bucket" {
  value = module.pas.pas_resources_backup_bucket
}

output "infrastructure_subnet_cidrs" {
  value = module.infra.infrastructure_subnet_cidrs
}

output "infrastructure_subnet_availability_zones" {
  value = module.infra.infrastructure_subnet_availability_zones
}

output "infrastructure_subnet_gateways" {
  value = module.infra.infrastructure_subnet_gateways
}

output "infrastructure_subnet_ids" {
  value = module.infra.infrastructure_subnet_ids
}

output "pas_subnet_cidrs" {
  value = module.pas.pas_subnet_cidrs
}

output "pas_subnet_availability_zones" {
  value = module.pas.pas_subnet_availability_zones
}

output "pas_subnet_gateways" {
  value = module.pas.pas_subnet_gateways
}

output "pas_subnet_ids" {
  value = module.pas.pas_subnet_ids
}

output "vms_security_group_id" {
  value = module.infra.vms_security_group_id
}

output "om_eni_id" {
  value = module.ops_manager.om_eni_id
}

output "om_eip_allocation" {
  value = module.ops_manager.om_eip_allocation
}

output "om_security_group_id" {
  value = module.ops_manager.security_group_id
}

output "rds_cidr_block" {
  value = module.calculated_subnets.rds_cidr
}

output "services_cidr_block" {
  value = module.calculated_subnets.services_cidr
}

output "public_cidr_block" {
  value = module.calculated_subnets.public_cidr
}

output "ops_manager_ip" {
  value = module.ops_manager.ip
}
