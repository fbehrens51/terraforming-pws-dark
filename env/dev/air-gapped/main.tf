terraform {
  backend "s3" {
    bucket = "eagle-state"
    key    = "dev/air-gapped/terraform.tfstate"
    encrypt = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
    dynamodb_table = "air-gapped-state"
  }
}

provider "aws" {
  region     = "us-east-1"
}

module "providers" {
  source = "../../../modules/dark_providers"
}

module "pas" {
  source              = "../../../terraforming-pas"
  availability_zones  = "${local.availability_zones}"
  dns_suffix          = "jgordon.xyz"
  env_name            = "${local.env_name}"
  rds_instance_count  = 0
  use_route53           = false
  use_tcp_routes        = false
  use_ssh_routes        = false
  vpc_id                = "${local.vpc_id}"
  ops_manager_role_name = "DIRECTOR"
  pas_bucket_role_name  = "pas_om_bucket_role"
  ops_manager_ami       = "ami-0b4e720c1858f1786"
  om_eip                = false
  om_eni                = false
  kms_key_name          = "pas_kms_key"
}

module "igw" {
  source = "../../../modules/gw/lookup"
  gateway_id = "igw-05d456b0f48a49220"
  vpc_id              = "${local.vpc_id}"
  availability_zones  = "${local.availability_zones}"
  public_subnets      = "${module.pas.public_subnets}"
}

module "elb" {
  source = "../../../modules/elb/create"
  env_name = "${local.env_name}"
  internetless = false
  public_subnet_ids = "${module.pas.public_subnets}"
  tags = "${local.tags}"
  vpc_id = "${local.vpc_id}"
  egress_cidrs = "${module.pas.pas_subnet_cidrs}"
}

locals {
  env_name            = "air-gapped"
  vpc_id              = "vpc-0d27315374a12fe98"
  availability_zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]

  tags =  {
    Team = "Dev"
    Project = "terraforming-pws-dark-CI"
  }
}
