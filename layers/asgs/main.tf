terraform {
  backend "s3" {
  }
}

provider "aws" {
}

module "providers" {
  source = "../../modules/dark_providers"
}

variable "remote_state_bucket" {
}

variable "remote_state_region" {
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


locals {
  secrets_bucket_name = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
}

data "aws_s3_bucket_objects" "blocked-cidr-objects" {
  bucket = local.secrets_bucket_name
  prefix = "blocked-cidrs/"
}

data "aws_s3_bucket_object" "blocked-cidrs" {
  count  = length(data.aws_s3_bucket_objects.blocked-cidr-objects.keys)
  key    = element(data.aws_s3_bucket_objects.blocked-cidr-objects.keys, count.index)
  bucket = data.aws_s3_bucket_objects.blocked-cidr-objects.bucket
}

output "blocked-cidrs" {
  value = data.aws_s3_bucket_object.blocked-cidrs.*.body
}
