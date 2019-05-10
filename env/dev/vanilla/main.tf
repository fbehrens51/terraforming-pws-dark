terraform {
  backend "s3" {
    bucket = "eagle-state"
    key = "dev/vanilla/terraform.tfstate"
    encrypt = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
    dynamodb_table = "vanilla-state"
  }
}

provider "aws" {
  region = "us-east-1"
}

module "providers" {
  source = "../../../modules/dark_providers"
}

module "pas" {
  source = "../../../terraforming-pas"
  availability_zones = "${local.availability_zones}"
  dns_suffix = "${local.dns_suffix}"
  env_name = "${local.env_name}"
  rds_instance_count = 0
  use_route53 = false
  use_tcp_routes = false
  use_ssh_routes = false
  vpc_id = "${module.vpc.vpc_id}"
  ops_manager_role_name = "${local.ops_manager_role_name}"
  pas_bucket_role_name = "${local.pas_bucket_role_name}"
  ops_manager_ami = "${local.ops_manager_ami}"
  om_eip = false
  om_eni = false
  kms_key_name = "${local.kms_key_name}"
}

module "vpc" {
  source = "../../../modules/vpc/create"
  name_prefix = "${local.env_name}-PROD"
  tags = "${local.tags}"
  vpc_cidr = "${local.vpc_cidr}"
}

module "igw" {
  source = "../../../modules/gw/create"
  name_prefix = "${local.env_name}-PROD"
  vpc_id = "${module.vpc.vpc_id}"
  availability_zones = "${local.availability_zones}"
  public_subnets = "${module.pas.public_subnets}"
  tags = "${local.tags}"
}

module "elb" {
  source = "../../../modules/elb/create"
  env_name = "${local.env_name}"
  internetless = false
  public_subnet_ids = "${module.pas.public_subnets}"
  tags = "${local.tags}"
  vpc_id = "${module.vpc.vpc_id}"
  egress_cidrs = "${module.pas.pas_subnet_cidrs}"
}

locals {
  env_name = "vanilla"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  vpc_cidr = "10.0.0.0/16"
  dns_suffix = "jgordon.xyz"
  ops_manager_role_name = "DIRECTOR"
  pas_bucket_role_name = "pas_om_bucket_role"
  ops_manager_ami = "ami-0b4e720c1858f1786"
  kms_key_name = "pas_kms_key"
  tags =  {
    Team = "Dev"
    Project = "terraforming-pws-dark-CI"
  }
}
