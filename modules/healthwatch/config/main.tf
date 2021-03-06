variable "root_domain" {
}

variable "grafana_elb_id" {
}

variable "grafana_server_ca_cert" {}
variable "grafana_server_cert" {}
variable "grafana_server_key" {}

variable "network_name" {
}

variable "availability_zones" {
  type = list(string)
}

variable "singleton_availability_zone" {
}

variable "health_check_availability_zone" {
}

variable "bosh_task_uaa_client_secret" {
}

variable "slack_webhook" {
}

variable "email_addresses" {
}

# the smtp_* variables configure healthwatch2 to postfix relay.
variable "smtp_from" {
}

variable "smtp_host" {
}

variable "smtp_client_password" {
}

variable "smtp_client_port" {
}

variable "smtp_client_user" {
}

# These syslog vars are unused, but will become used once the healthwatch team adds syslog forwarding to the tile
variable "syslog_host" {
}

variable "syslog_port" {
}

variable "syslog_ca_cert" {
}

variable "secrets_bucket_name" {
}

variable "healthwatch_config" {
}

variable "healthwatch_pas_exporter_config" {
}

variable "region" {
}

variable "metrics_key" {
}

variable "grafana_uaa_client_secret" {
}

variable "grafana_additional_cipher_suites" {
  type = list(string)
}

variable "scale" {
  type = map(map(string))
}

data "template_file" "hw_vpc_azs" {
  count = length(var.availability_zones)

  template = <<EOF
- name: $${hw_subnet_availability_zone}
EOF


  vars = {
    hw_subnet_availability_zone = var.availability_zones[count.index]
  }
}

module "domains" {
  source      = "../../domains"
  root_domain = var.root_domain
}

locals {
  healthwatch_config = templatefile("${path.module}/healthwatch_config.tpl", {
    scale                            = var.scale["p-healthwatch2"]
    grafana_additional_cipher_suites = join(",", var.grafana_additional_cipher_suites)
    grafana_root_url                 = "https://${module.domains.grafana_fqdn}"
    fluentd_root_url                 = "${module.domains.fluentd_fqdn}:9200"
    canary_url                       = "https://${module.domains.apps_manager_fqdn}"
    ops_canary_url                   = "https://${module.domains.om_fqdn}/api/v0/info"
    metrics_key                      = var.metrics_key
    root_ca_cert                     = var.grafana_server_ca_cert
    grafana_server_cert              = var.grafana_server_cert
    grafana_server_key               = var.grafana_server_key
    network_name                     = var.network_name
    hw_vpc_azs                       = indent(2, join("", data.template_file.hw_vpc_azs.*.rendered))
    singleton_availability_zone      = var.singleton_availability_zone
    region                           = var.region
    grafana_elb_id                   = var.grafana_elb_id
    grafana_uaa_client_secret        = var.grafana_uaa_client_secret
    uaa_url                          = "https://uaa.${module.domains.system_fqdn}"
    smtp_enabled                     = var.smtp_from == "" ? false : true
    smtp_from                        = var.smtp_from
    smtp_host                        = var.smtp_host
    smtp_password                    = var.smtp_client_password
    smtp_port                        = var.smtp_client_port
    smtp_user                        = var.smtp_client_user
    email_addresses                  = var.email_addresses
    slack_enabled                    = var.slack_webhook == "" ? false : true
    slack_webhook                    = var.slack_webhook
    syslog_host                      = var.syslog_host
    syslog_port                      = var.syslog_port
    syslog_ca_cert                   = var.syslog_ca_cert
  })
}

resource "aws_s3_bucket_object" "healthwatch_template" {
  bucket  = var.secrets_bucket_name
  key     = var.healthwatch_config
  content = local.healthwatch_config
}

locals {
  healthwatch_pas_exporter_config = templatefile("${path.module}/healthwatch_pas_exporter_config.tpl", {
    scale                          = var.scale["p-healthwatch2-pas-exporter"]
    bosh_client_username           = "healthwatch_client"
    bosh_client_password           = var.bosh_task_uaa_client_secret
    network_name                   = var.network_name
    hw_vpc_azs                     = indent(2, join("", data.template_file.hw_vpc_azs.*.rendered))
    singleton_availability_zone    = var.singleton_availability_zone
    health_check_availability_zone = var.health_check_availability_zone
    syslog_host                    = var.syslog_host
    syslog_port                    = var.syslog_port
    syslog_ca_cert                 = var.syslog_ca_cert
  })
}

resource "aws_s3_bucket_object" "healthwatch_pas_exporter_template" {
  bucket  = var.secrets_bucket_name
  key     = var.healthwatch_pas_exporter_config
  content = local.healthwatch_pas_exporter_config
}
