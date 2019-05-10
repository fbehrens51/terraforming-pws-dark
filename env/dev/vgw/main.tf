terraform {
  backend "s3" {
    bucket = "eagle-state"
    key    = "dev/vgw/terraform.tfstate"
    encrypt = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
    dynamodb_table = "vgw-state"
  }
}

provider "aws" {
  region     = "us-east-1"
}

module "providers" {
  source = "../../../modules/dark_providers"
}

module "pas" {
  source                = "../../../terraforming-pas"
  availability_zones    = "${local.availability_zones}"
  dns_suffix            = "jgordon.xyz"
  env_name              = "${local.env_name}"
  rds_instance_count    = 0
  use_route53           = false
  use_tcp_routes        = false
  use_ssh_routes        = false
  vpc_id                = "${local.vpc_id}"
  ops_manager_role_name = "DIRECTOR"
  pas_bucket_role_name  = "pas_om_bucket_role"
  ops_manager_ami       = "ami-0b4e720c1858f1786"
  internetless          = true
  ops_manager_private   = false
  om_eip                = false
  om_eni                = true
  om_public_subnet      = true
  kms_key_name          = "pas_kms_key"
}

module "vgw" {
  source = "../../../modules/gw/lookup"
  availability_zones = "${local.availability_zones}"
  gateway_id = "vgw-03a6980cacc039860"
  public_subnets = "${module.pas.public_subnets}"
  vpc_id =  "${local.vpc_id}"
}

module "elb" {
  source = "../../../modules/elb/create"
  env_name = "${local.env_name}"
  internetless = true
  public_subnet_ids = "${module.pas.public_subnets}"
  tags = "${local.tags}"
  vpc_id = "${local.vpc_id}"
  egress_cidrs = "${module.pas.pas_subnet_cidrs}"
}

locals {
  env_name            = "vgw"
  vpc_id              = "vpc-0346f70ea7ef6293a"
  availability_zones  = ["us-east-1a", "us-east-1b"]

  tags =  {
    Team = "Dev"
    Project = "terraforming-pws-dark-CI"
  }
}
