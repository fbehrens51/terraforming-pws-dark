terraform {
  backend "s3" {
    bucket = "eagle-state"
    key = "dev/vgw/terraform.tfstate"
    encrypt = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
    dynamodb_table = "vgw-state"
  }
}

provider "aws" {
  region = "us-east-1"
}

module "providers" {
  source = "../../../modules/dark_providers"
}

// pre-reqs
module "paperwork" {
  source = "../../../modules/paperwork"
  vpc_cidr = "${local.vpc_cidr}"
  tags = "${local.tags}"
}

// use-case

module "pas" {
  source = "../../../terraforming-pas"
  availability_zones = "${local.availability_zones}"
  dns_suffix = "jgordon.xyz"
  env_name = "${local.env_name}"
  rds_instance_count = 0
  use_route53 = false
  use_tcp_routes = false
  use_ssh_routes = false
  vpc_id = "${module.paperwork.vpc_id}"
  ops_manager_role_name = "${module.paperwork.director_role_name}"
  pas_bucket_role_name = "${module.paperwork.bucket_role_name}"
  ops_manager_ami = "${local.ops_manager_ami}"
  internetless = true
  ops_manager_private = false
  om_eip = false
  om_eni = true
  om_public_subnet = true
  kms_key_name = "${module.paperwork.key_id}"
  pas_bucket_role_arn = "${module.paperwork.bucket_role_arn}"
}

module "vgw" {
  source = "../../../modules/gw/lookup"
  availability_zones = "${local.availability_zones}"
  gateway_id = "${module.paperwork.ig_id}"
  public_subnets = "${module.pas.public_subnets}"
  vpc_id = "${module.paperwork.vpc_id}"
}

module "elb" {
  source = "../../../modules/elb/create"
  env_name = "${local.env_name}"
  internetless = true
  public_subnet_ids = "${module.pas.public_subnets}"
  tags = "${local.tags}"
  vpc_id = "${module.paperwork.vpc_id}"
  egress_cidrs = "${module.pas.pas_subnet_cidrs}"
  ops_manager_instance_id = "${module.pas.ops_manager_instance_id}"
}

locals {
  env_name = "vgw"
  vpc_cidr = "10.0.0.0/20"
  availability_zones = ["us-east-1a", "us-east-1b"]
  ops_manager_ami = "ami-0b4e720c1858f1786"

  tags = {
    Name = "vgw pas"
  }
}
