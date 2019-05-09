provider "aws" {
  version = "~> 1.54.0"
}

provider "random" {
  version = "~> 1.3.0"
}

provider "tls" {
  version = "~> 1.2.0"
}

provider "template" {
  version = "~> 2.0.0"
}

provider "null" {}

terraform {
  required_version = "< 0.12.0"
}
