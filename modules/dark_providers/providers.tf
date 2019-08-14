provider "aws" {
  version = "<= 1.54"
}

provider "random" {
  version = "~> 2.1.0"
}

provider "tls" {
  version = "~> 1.2.0"
}

provider "template" {
  version = "~> 2.0.0"
}

provider "null" {
  version = "~> 2.0.0"
}

provider "external" {
  version = "1.1.2"
}

provider "dns" {
  version = "2.1.1"
}

terraform {
  required_version = "< 0.12.0"
}
