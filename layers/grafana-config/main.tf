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

data "terraform_remote_state" "bootstrap_fluentd" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_fluentd"
    region  = var.remote_state_region
    encrypt = true
  }
}

variable "namespaces" {
  default = "LogMetrics"
}

variable "grafana_auth" {
}

variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "global_vars" {
  type = any
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

variable "aws_base_domain" {
  default = "aws.amazon.com"
}

data "aws_region" "current" {
}

locals {
  env_name       = var.global_vars.env_name
  slack_default  = var.slack_webhook != "" ? true : false
  log_group_name = data.terraform_remote_state.bootstrap_fluentd.outputs.log_group_name
  region         = data.aws_region.current.name
  dashboard_name = replace("${local.env_name} AntiVirus", " ", "_")
}


resource "aws_cloudwatch_dashboard" "clamav" {
  dashboard_name = local.dashboard_name

  dashboard_body = <<-EOF
    {
        "widgets": [
            {
                "type": "log",
                "x": 0,
                "y": 0,
                "width": 24,
                "height": 6,
                "properties": {
                    "query": "SOURCE '${local.log_group_name}' | filter @message like / FOUND\"/ | parse message \"*: * FOUND\" as file, sig | display @timestamp, host, ident, file, sig",
                    "region": "${local.region}",
                    "stacked": false,
                    "view": "table"
                }
            }
        ]
    }
    EOF
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

  send_reminder = true
  frequency     = "24h"

  settings = {
    url = var.slack_webhook
  }
}

resource "grafana_alert_notification" "email" {
  count      = var.email_addresses == "" ? 0 : 1
  name       = "PWS Dark Email Notifications"
  type       = "email"
  is_default = !local.slack_default

  send_reminder = true
  frequency     = "24h"

  settings = {
    addresses = var.email_addresses
  }
}

resource "grafana_data_source" "cloudwatch" {
  type = "cloudwatch"
  name = "cloudwatch"

  json_data {
    auth_type                 = ""
    default_region            = local.region
    custom_metrics_namespaces = var.namespaces
  }
}

resource "grafana_dashboard" "vm-resources" {
  config_json = file("dashboards/vm-resources.json")
}

resource "grafana_dashboard" "cloudwatch-log-forwarder" {
  config_json = file("dashboards/cloudwatch-log-forwarder.json")
}

resource "grafana_dashboard" "vm-health" {
  config_json = file("dashboards/vm-health.json")
}

resource "grafana_dashboard" "fluentd" {
  config_json = file("dashboards/fluentd.json")
}

resource "grafana_dashboard" "prometheus" {
  config_json = file("dashboards/prometheus.json")
}

resource "grafana_dashboard" "concourse" {
  config_json = file("dashboards/concourse.json")
}

resource "grafana_dashboard" "events-logger" {
  config_json = file("dashboards/events-logger.json")
}

data "template_file" "clamav_dashboard" {
  template = file("dashboards/antivirus-alerts.json.tpl")
  vars = {
    region          = local.region
    dashboard_name  = local.dashboard_name
    log_group_name  = local.log_group_name
    aws_base_domain = var.aws_base_domain
  }
}

resource "grafana_dashboard" "clamav" {
  config_json = data.template_file.clamav_dashboard.rendered
}
