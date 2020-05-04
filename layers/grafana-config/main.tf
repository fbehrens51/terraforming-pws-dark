provider "aws" {
}

module "providers" {
  source = "../../modules/dark_providers"
}

terraform {
  backend "s3" {
  }
}

data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "paperwork"
    region  = var.remote_state_region
    encrypt = true
  }
}

variable "grafana_auth" {
}

variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

provider "grafana" {
  url  = "https://${module.domains.grafana_fqdn}"
  auth = var.grafana_auth
}

variable "slack_webhook" {
  default = ""
}

variable "email_addresses" {
  default = ""
}

locals {
  slack_default = var.slack_webhook != "" ? true : false
}

module "domains" {
  source      = "../../modules/domains"
  root_domain = data.terraform_remote_state.paperwork.outputs.root_domain
}

resource "grafana_alert_notification" "slack" {
  count      = var.slack_webhook == "" ? 0 : 1
  name       = "PWS Dark Notifications"
  type       = "slack"
  is_default = local.slack_default

  settings = {
    url = var.slack_webhook
  }
}

resource "grafana_alert_notification" "email" {
  count      = var.email_addresses == "" ? 0 : 1
  name       = "PWS Dark Email Notifications"
  type       = "email"
  is_default = ! local.slack_default

  settings = {
    addresses = var.email_addresses
  }
}

resource "grafana_dashboard" "vm-resources" {
  config_json = file("dashboards/vm-resources.json")
}

resource "grafana_dashboard" "vm-health" {
  config_json = file("dashboards/vm-health.json")
}
