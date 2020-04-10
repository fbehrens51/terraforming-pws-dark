variable "om_url" {
}

variable "root_domain" {
}

variable "grafana_elb_id" {
}

variable "grafana_server_ca_cert" {}
variable "grafana_server_cert" {}
variable "grafana_server_key" {}

variable "network_name" {
}

variable "env_name" {
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

variable "splunk_syslog_host" {
}

variable "splunk_syslog_port" {
}

variable "splunk_syslog_ca_cert" {
}

variable "secrets_bucket_name" {
}

variable "healthwatch_config" {
}

variable "healthwatch2_config" {
}

variable "healthwatch2_pas_exporter_config" {
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

data "template_file" "healthwatch2_config" {
  template = file("${path.module}/healthwatch2_config.tpl")

  vars = {
    grafana_root_url            = "https://${module.domains.grafana_fqdn}"
    canary_url                  = "https://${module.domains.apps_manager_fqdn}"
    root_ca_cert                = var.grafana_server_ca_cert
    grafana_server_cert         = var.grafana_server_cert
    grafana_server_key          = var.grafana_server_key
    network_name                = var.network_name
    hw_vpc_azs                  = indent(2, join("", data.template_file.hw_vpc_azs.*.rendered))
    singleton_availability_zone = var.singleton_availability_zone
    grafana_elb_id              = var.grafana_elb_id
  }
}

resource "aws_s3_bucket_object" "healthwatch2_template" {
  bucket  = var.secrets_bucket_name
  key     = var.healthwatch2_config
  content = data.template_file.healthwatch2_config.rendered
}

data "template_file" "healthwatch2_pas_exporter_config" {
  template = file("${path.module}/healthwatch2_pas_exporter_config.tpl")

  vars = {
    bosh_client_username           = "healthwatch_client"
    bosh_client_password           = var.bosh_task_uaa_client_secret
    network_name                   = var.network_name
    hw_vpc_azs                     = indent(2, join("", data.template_file.hw_vpc_azs.*.rendered))
    singleton_availability_zone    = var.singleton_availability_zone
    health_check_availability_zone = var.health_check_availability_zone
  }
}

resource "aws_s3_bucket_object" "healthwatch2_pas_exporter_template" {
  bucket  = var.secrets_bucket_name
  key     = var.healthwatch2_pas_exporter_config
  content = data.template_file.healthwatch2_pas_exporter_config.rendered
}

data "template_file" "healthwatch_config" {
  template = file("${path.module}/healthwatch_config.tpl")

  vars = {
    foundation_name = var.env_name
    om_url          = var.om_url
    network_name    = var.network_name
    //availability_zones value isn't being used to configure AZs, so hard coding to use singleton_az for now
    //    availability_zones = "[${join(",", var.availability_zones)}]"
    hw_vpc_azs = indent(2, join("", data.template_file.hw_vpc_azs.*.rendered))
    //    availability_zones = "${var.singleton_availability_zone}"
    //
    singleton_availability_zone    = var.singleton_availability_zone
    health_check_availability_zone = var.health_check_availability_zone
    env_name                       = var.env_name
    bosh_task_uaa_client_secret    = var.bosh_task_uaa_client_secret
    splunk_syslog_host             = var.splunk_syslog_host
    splunk_syslog_port             = var.splunk_syslog_port
    splunk_syslog_ca_cert          = var.splunk_syslog_ca_cert
  }
}

resource "aws_s3_bucket_object" "healthwatch_template" {
  bucket  = var.secrets_bucket_name
  key     = var.healthwatch_config
  content = data.template_file.healthwatch_config.rendered
}
