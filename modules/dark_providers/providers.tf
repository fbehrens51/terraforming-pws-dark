provider "aws" {
  version = "~> 2.43.0"
}

provider "random" {
  version = "~> 2.1.0"
}

provider "tls" {
  version = "~> 2.1.1"
}

provider "template" {
  version = "~> 2.1.2"
}

provider "null" {
  version = "~> 2.1.2"
}

provider "external" {
  version = "1.1.2"
}

provider "dns" {
  version = "2.1.1"
}

provider "local" {
  version = "1.4.0"
}

terraform {
  required_version = "~> 0.12.18"
}
