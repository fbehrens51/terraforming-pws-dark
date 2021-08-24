terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    grafana = {
      source = "grafana/grafana"
    }
    template = {
      source = "hashicorp/template"
    }
  }
  required_version = "~> 1.0"
}
