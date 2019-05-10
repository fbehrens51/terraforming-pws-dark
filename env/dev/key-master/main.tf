terraform {
  backend "s3" {
    bucket = "eagle-state"
    key    = "dev/key-master/terraform.tfstate"
    encrypt = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
    dynamodb_table = "key-master-state"
  }
}

provider "aws" {
  region     = "us-east-1"
}

module "providers" {
  source = "../../../modules/dark_providers"
}

module "kms" {
  source = "../../../modules/kms/create"
  key_name = "key-master-${random_integer.key-suffix.result}"
  deletion_window = 7
}

resource "random_integer" "key-suffix" {
  min = 1
  max = 100000
}

output "kms_key_id" {
  value = "${module.kms.kms_key_id}"
}

output "kms_key_alias_arn" {
  value = "${module.kms.kms_key_alias_arn}"
}
