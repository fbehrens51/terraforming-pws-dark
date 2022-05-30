terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.75"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }

    template = {
      source  = "hashicorp/template"
      version = "~> 2.2"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.1"
    }

    external = {
      source  = "hashicorp/external"
      version = "~> 2.1"
    }

    dns = {
      source  = "hashicorp/dns"
      version = "~> 3.2"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.1"
    }

    grafana = {
      source  = "grafana/grafana"
      version = "~> 1.13.4"
    }
  }
}
