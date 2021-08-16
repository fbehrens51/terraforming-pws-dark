terraform {
  # Version of Terraform to include in the bundle. An exact version number
  # is required.
  version = "0.14.11"
}

# Define which provider plugins are to be included
providers {

  # Pin to a version that works on C2S
  aws = {
    versions = ["2.49.0"]
  }

  tls = {
    versions = ["~> 2.1.1"]
  }

  random = {
    versions = ["~> 2.1.0"]
  }

  template = {
    versions = ["~> 2.1.2"]
  }

  null = {
    versions = ["~> 2.1.2"]
  }

  external = {
    versions = ["~> 1.1.2"]
  }

  dns = {
    versions = ["~> 2.1.1"]
  }

  local = {
    versions = ["~> 1.4.0"]
  }

  grafana = {
    source = "grafana/grafana"
    versions = ["~> 1.7.0"]
  }

}
