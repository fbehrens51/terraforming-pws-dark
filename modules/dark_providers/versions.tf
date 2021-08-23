terraform {
  required_version = ">= 1.0.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "2.49.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 2.1.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 2.1.0"
    }

    template = {
      source  = "hashicorp/template"
      version = "~> 2.1.2"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 2.1.2"
    }

    external = {
      source  = "hashicorp/external"
      version = "~> 1.1.2"
    }

    dns = {
      source  = "hashicorp/dns"
      version = "~> 2.1.1"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 1.4.0"
    }

    grafana = {
      source  = "grafana/grafana"
      version = "~> 1.13.4"
    }
  }
}
