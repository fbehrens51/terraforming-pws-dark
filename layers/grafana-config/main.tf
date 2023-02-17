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

data "terraform_remote_state" "bootstrap_loki" {
  count   = var.enable_loki ? 1 : 0
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_loki"
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

variable "enable_loki" {
  type    = bool
  default = false
}

data "aws_region" "current" {
}

locals {
  env_name       = var.global_vars.env_name
  slack_default  = var.slack_webhook != "" ? true : false
  log_group_name = data.terraform_remote_state.bootstrap_fluentd.outputs.log_group_name
  loki_url       = data.terraform_remote_state.bootstrap_loki[0].outputs.loki_url
  region         = data.aws_region.current.name
  dashboard_name = replace("${local.env_name} AntiVirus", " ", "_")
  billing_region = (
    local.region == "us-east-2" ? "us-east-1" :
    local.region == "us-west-1" ? "us-east-1" :
    local.region == "us-west-2" ? "us-east-1" :
    local.region
  )
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

resource "grafana_data_source" "promloki" {
  count    = var.enable_loki ? 1 : 0
  type     = "prometheus"
  name     = "PromLoki"
  uid      = "twsPromLokiDataSource"
  url      = "${local.loki_url}/loki"
  username = data.terraform_remote_state.bootstrap_loki[0].outputs.loki_username

  json_data_encoded = jsonencode({
    tls_auth = true
  })

  secure_json_data_encoded = jsonencode({
    basic_auth_password = data.terraform_remote_state.bootstrap_loki[0].outputs.loki_password
    tls_client_cert     = data.terraform_remote_state.paperwork.outputs.loki_client_cert
    tls_client_key      = data.terraform_remote_state.paperwork.outputs.loki_client_key
  })
}

resource "grafana_data_source" "loki" {
  count    = var.enable_loki ? 1 : 0
  type     = "loki"
  name     = "Loki"
  uid      = "twsLokiDataSource"
  url      = local.loki_url
  username = data.terraform_remote_state.bootstrap_loki[0].outputs.loki_username

  json_data_encoded = jsonencode({
    tls_auth = true
  })

  secure_json_data_encoded = jsonencode({
    basic_auth_password = data.terraform_remote_state.bootstrap_loki[0].outputs.loki_password
    tls_client_cert     = data.terraform_remote_state.paperwork.outputs.loki_client_cert
    tls_client_key      = data.terraform_remote_state.paperwork.outputs.loki_client_key
  })
}

resource "grafana_data_source" "cloudwatch" {
  type = "cloudwatch"
  name = "cloudwatch"
  uid  = "twsCloudWatchDataSource"
  url  = "https://monitoring${trimprefix(data.aws_region.current.endpoint, "ec2")}"

  json_data_encoded = jsonencode({
    auth_type                 = ""
    default_region            = local.region
    custom_metrics_namespaces = var.namespaces
  })
}

resource "grafana_dashboard" "vm-resources" {
  config_json = file("dashboards/vm-resources.json")
}

# Internal
resource "grafana_dashboard" "nat-performance-troubleshooting" {
  config_json = file("dashboards/nat-performance-troubleshooting.json")
}

# Internal
resource "grafana_dashboard" "go-router-traffic-monitoring" {
  config_json = file("dashboards/go-router-traffic-monitoring.json")
}

# Internal
resource "grafana_dashboard" "ami-network-performance" {
  config_json = file("dashboards/ami-network-performance.json")
}

# Internal
resource "grafana_dashboard" "cloudwatch-log-forwarder" {
  config_json = file("dashboards/cloudwatch-log-forwarder.json")
}

resource "grafana_dashboard" "vm-health" {
  config_json = file("dashboards/vm-health.json")
}

# Internal
resource "grafana_dashboard" "fluentd" {
  config_json = file("dashboards/fluentd.json")
}

# Prometheus 2.0 Overview by jeremy b, id=3662
resource "grafana_dashboard" "prometheus" {
  config_json = file("dashboards/prometheus.json")
}

resource "grafana_dashboard" "concourse" {
  config_json = file("dashboards/concourse.json")
}

# Node Exporter Server Metrics by Knut Ytterhaug, id=405
resource "grafana_dashboard" "server-metrics" {
  config_json = file("dashboards/server-metrics.json")
}

# Internal
resource "grafana_dashboard" "lokiprom-demo" {
  config_json = file("dashboards/lokiprom-demo.json")
}

# Internal
resource "grafana_dashboard" "credhub-admin" {
  config_json = file("dashboards/credhub-admin.json")
}

# Internal
resource "grafana_dashboard" "events-logger" {
  config_json = file("dashboards/events-logger.json")
}

# Loki & Promtail by zakkg3, id=10880
resource "grafana_dashboard" "loki" {
  count       = var.enable_loki ? 1 : 0
  config_json = file("dashboards/loki.json")
}

# Bind9 Exporter DNS by Paulo Castro, id=12309
resource "grafana_dashboard" "bind" {
  config_json = file("dashboards/bind.json")
}

data "template_file" "aws_billing_dashboard" {
  template = file("dashboards/aws-billing.json.tpl")
  vars = {
    billing_region = local.billing_region
  }
}

# Internal - copied from AWS Billing by Monitoring Artist, id=139
resource "grafana_dashboard" "aws_billing" {
  config_json = data.template_file.aws_billing_dashboard.rendered
}

data "template_file" "aws_rds_dashboard" {
  template = file("dashboards/aws-rds.json.tpl")
  vars = {
    region   = local.region
    env_name = replace(local.env_name, " ", "-")
  }
}

# Internal - copied from AWS rds by Monitoring Artist, id=707
resource "grafana_dashboard" "aws_rds" {
  config_json = data.template_file.aws_rds_dashboard.rendered
}

# alertmanager by Martin Chodur, id=9578
resource "grafana_dashboard" "alertmanager" {
  config_json = file("dashboards/alertmanager.json")
}

# node-exporter-full by rfmoz, id=1860
resource "grafana_dashboard" "node_exporter_full" {
  config_json = file("dashboards/node-exporter-full.json")
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
