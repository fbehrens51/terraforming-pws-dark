provider "aws" {
  region = "${var.region}"
}

module "providers" {
  source = "../../modules/dark_providers"
}

terraform {
  backend "s3" {}
}

data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "layer0-paperwork"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

data "terraform_remote_state" "routes" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "layer1-routes"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

module "infra" {
  source = "../../modules/infra"

  env_name               = "${var.env_name}"
  availability_zones     = "${var.availability_zones}"
  internetless           = "${var.internetless}"
  dns_suffix             = ""
  tags                   = "${var.tags}"
  use_route53            = false
  vpc_id                 = "${local.vpc_id}"
  public_route_table_id  = "${local.route_table_id}"
  private_route_table_id = "${data.terraform_remote_state.routes.pas_private_vpc_route_table_id}"
}

module "pas" {
  source             = "../../modules/pas"
  availability_zones = "${var.availability_zones}"
  dns_suffix         = ""
  env_name           = "${var.env_name}"
  public_subnet_ids  = "${module.infra.public_subnet_ids}"
  route_table_id     = "${data.terraform_remote_state.routes.pas_private_vpc_route_table_id}"
  tags               = "${var.tags}"
  vpc_id             = "${local.vpc_id}"
  zone_id            = "${module.infra.zone_id}"
  bucket_suffix      = "${local.bucket_suffix}"
}

module "portal_cache" {
  source             = "../../modules/portal-cache"
  availability_zones = "${var.availability_zones}"
  env_name           = "${var.env_name}"
  vpc_id             = "${local.vpc_id}"
}

module "om_key_pair" {
  source = "../../modules/key_pair"
  name   = "${local.om_key_name}"
}

module "rds" {
  source = "../../modules/rds"

  rds_db_username    = "${var.rds_db_username}"
  rds_instance_class = "${var.rds_instance_class}"
  rds_instance_count = "1"

  engine         = "mariadb"
  engine_version = "10.1.31"
  db_port        = 3306

  env_name           = "${var.env_name}"
  availability_zones = "${var.availability_zones}"
  vpc_id             = "${module.infra.vpc_id}"
  tags               = "${var.tags}"
}

module "pas_elb" {
  source            = "../../modules/elb/create"
  env_name          = "${var.env_name}"
  internetless      = "${var.internetless}"
  public_subnet_ids = "${module.infra.public_subnet_ids}"
  tags              = "${var.tags}"
  vpc_id            = "${local.vpc_id}"
  egress_cidrs      = "${module.pas.pas_subnet_cidrs}"
  short_name        = "pas"
}

module "om_elb" {
  source            = "../../modules/elb/create"
  env_name          = "${var.env_name}"
  internetless      = "${var.internetless}"
  public_subnet_ids = "${module.infra.public_subnet_ids}"
  tags              = "${var.tags}"
  vpc_id            = "${local.vpc_id}"
  egress_cidrs      = "${module.infra.infrastructure_subnet_cidrs}"
  short_name        = "om"
}

data "aws_vpc" "cp_vpc" {
  id = "${local.cp_vpc_id}"
}

data "aws_vpc" "bastion_vpc" {
  id = "${local.bastion_vpc_id}"
}

module "ops_manager" {
  source = "../../modules/ops_manager/infra"

  bucket_suffix         = "${local.bucket_suffix}"
  dns_suffix            = ""
  env_name              = "${var.env_name}"
  om_eip                = false
  ops_manager_role_name = "${data.terraform_remote_state.paperwork.director_role_name}"
  private               = true
  subnet_id             = "${module.infra.infrastructure_subnet_ids[0]}"
  tags                  = "${var.tags}"
  use_route53           = false
  vm_count              = "1"
  vpc_id                = "${local.vpc_id}"
  zone_id               = "${var.availability_zones[0]}"
  ingress_rules         = ["${local.ingress_rules}"]
}

resource "random_integer" "bucket" {
  min = 1
  max = 100000
}

variable "remote_state_bucket" {}
variable "remote_state_region" {}
variable "rds_db_username" {}
variable "rds_instance_class" {}

variable "env_name" {}

variable "availability_zones" {
  type = "list"
}

variable "internetless" {}

variable "tags" {
  type = "map"
}

variable "s3_endpoint" {}
variable "ec2_endpoint" {}
variable "elb_endpoint" {}
variable "region" {}

locals {
  cp_vpc_id      = "${data.terraform_remote_state.paperwork.cp_vpc_id}"
  bastion_vpc_id = "${data.terraform_remote_state.paperwork.bastion_vpc_id}"
  vpc_id         = "${data.terraform_remote_state.paperwork.pas_vpc_id}"
  route_table_id = "${data.terraform_remote_state.routes.pas_public_vpc_route_table_id}"
  bucket_suffix  = "${random_integer.bucket.result}"
  om_key_name    = "${var.env_name}-om"

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

output "public_subnet_ids" {
  value = "${module.infra.public_subnet_ids}"
}

output "pas_elb_id" {
  value = "${module.pas_elb.my_elb_id}"
}

output "rds_address" {
  value = "${module.rds.rds_address}"
}

output "rds_password" {
  value = "${module.rds.rds_password}"
}

output "rds_port" {
  value = "${module.rds.rds_port}"
}

output "rds_username" {
  value = "${module.rds.rds_username}"
}

output "pas_buildpacks_bucket" {
  value = "${module.pas.pas_buildpacks_bucket}"
}

output "pas_droplets_bucket" {
  value = "${module.pas.pas_droplets_bucket}"
}

output "pas_packages_bucket" {
  value = "${module.pas.pas_packages_bucket}"
}

output "pas_resources_bucket" {
  value = "${module.pas.pas_resources_bucket}"
}

output "pas_subnet_cidrs" {
  value = "${module.pas.pas_subnet_cidrs}"
}

output "pas_subnet_availability_zones" {
  value = "${module.pas.pas_subnet_availability_zones}"
}

output "pas_subnet_gateways" {
  value = "${module.pas.pas_subnet_gateways}"
}

output "pas_subnet_ids" {
  value = "${module.pas.pas_subnet_ids}"
}

output "vms_security_group_id" {
  value = "${module.infra.vms_security_group_id}"
}

output "om_eni_id" {
  value = "${module.ops_manager.om_eni_id}"
}

output "om_elb_id" {
  value = "${module.om_elb.my_elb_id}"
}

output "om_eip_allocation_id" {
  value = "${module.ops_manager.om_eip_allocation_id}"
}

output "om_private_key_pem" {
  value = "${module.om_key_pair.private_key_pem}"
}

output "om_security_group_id" {
  value = "${module.ops_manager.security_group_id}"
}

output "om_ssh_public_key_pair_name" {
  value = "${local.om_key_name}"
}

output "redis_host" {
  value = "${module.portal_cache.redis_host}"
}

output "redis_port" {
  value = "${module.portal_cache.redis_port}"
}

output "redis_password" {
  value = "${module.portal_cache.redis_password}"
}
