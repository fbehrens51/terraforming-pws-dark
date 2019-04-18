terraform {
  required_version = "< 0.12.0"

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
  version = "~> 1.60"
}

provider "random" {
  version = "~> 2.0"
}

provider "template" {
  version = "~> 2.0"
}

provider "tls" {
  version = "~> 1.2"
}

module "kms" {
  source = "../../../modules/kms/create"
  key_name = "key-master"
  deletion_window = 8
}

output "kms_key_id" {
  value = "${module.kms.kms_key_id}"
}
