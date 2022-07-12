terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/local"
    }
  }
  required_version = "~> 1.0"
}
