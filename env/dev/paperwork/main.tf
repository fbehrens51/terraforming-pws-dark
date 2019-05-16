terraform {
  backend "s3" {
    bucket = "eagle-state"
    key = "dev/paperwork/terraform.tfstate"
    encrypt = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
    dynamodb_table = "paperwork-state"
  }
}

provider "aws" {
  region = "us-east-1"
}

module "providers" {
  source = "../../../modules/dark_providers"
}

module "paperwork" {
  source = "../../../modules/paperwork"
  tags = "${local.tags}"
  vpc_cidr = "${local.vpc_cidr}"
}

locals {
  vpc_cidr = "10.0.0.0/16"
  tags =  {
    Name = "paperwork"
  }
}
