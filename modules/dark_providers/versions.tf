terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    dns = {
      source = "hashicorp/dns"
    }
    external = {
      source = "hashicorp/external"
    }
    grafana = {
      source = "grafana/grafana"
    }
    local = {
      source = "hashicorp/local"
    }
    null = {
      source = "hashicorp/null"
    }
    random = {
      source = "hashicorp/random"
    }
    template = {
      source = "hashicorp/template"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
  required_version = ">= 0.13"
}
