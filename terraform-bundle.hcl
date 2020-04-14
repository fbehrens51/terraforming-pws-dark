terraform {
  # Version of Terraform to include in the bundle. An exact version number
  # is required.
  version = "0.12.20"
}

# Define which provider plugins are to be included
providers {

  # Pin to a version that works on C2S
  aws = ["2.49.0"]

  tls = ["~> 2.1.1"]

  random = ["~> 2.1.0"]

  template = ["~> 2.1.2"]

  null = ["~> 2.1.2"]

  external = ["~> 1.1.2"]

  dns = ["~> 2.1.1"]

  local = ["~> 1.4.0"]

  grafana = ["~> 1.5.0"]

}
