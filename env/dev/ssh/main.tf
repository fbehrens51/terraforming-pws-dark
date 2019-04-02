terraform {
  required_version = "< 0.12.0"

  backend "s3" {
    bucket = "eagle-state"
    key    = "dev/ssh/terraform.tfstate"
    encrypt = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
    dynamodb_table = "state_lock"
  }
}

provider "aws" {
  region     = "us-east-1"
  version = "~> 1.60"
}

provider "random" {
  version = "~> 2.0"
}

provider "template" {
  version = "~> 1.0"
}

provider "tls" {
  version = "~> 1.2"
}

module "pas" {
  source              = "../../../terraforming-pas"
  availability_zones  = "${local.availability_zones}"
  dns_suffix          = "jgordon.xyz"
  env_name            = "ssh"
  rds_instance_count  = 0
  use_route53           = false
  use_tcp_routes        = false
  use_ssh_routes        = false
  vpc_id                = "${local.vpc_id}"
  ops_manager_role_name = "DIRECTOR"
  ops_manager_ami       = "ami-0b4e720c1858f1786"
}

module "igw" {
  source = "../../../modules/gw/lookup"
  gateway_id = "igw-031c26ac18e580e2a"
  vpc_id              = "${local.vpc_id}"
  availability_zones  = "${local.availability_zones}"
  public_subnets      = "${module.pas.public_subnets}"
}

locals {
  vpc_id = "vpc-053b17e24125579d5"
  availability_zones  = ["us-east-1a", "us-east-1b"]
}
