terraform {
  backend "s3" {
  }
}

provider "aws" {
}

module "providers" {
  source = "../../modules/dark_providers"
}

variable "remote_state_region" {
}

variable "remote_state_bucket" {
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

module "encrypt_amazon2_ami" {
  source     = "../../modules/amis/encrypted/amazon2/create"
  kms_key_id = data.terraform_remote_state.paperwork.outputs.kms_key_arn
}

output "encrypted_amazon2_ami_id" {
  value = module.encrypt_amazon2_ami.encrypted_ami_id
}

