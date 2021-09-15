variable "public_bucket_name" {
}

variable "public_bucket_url" {
}

variable "ca_cert" {
}

variable "fluentd_bundle_key" {
  description = "Fluentd bundle S3 object key, aka filename."
}

variable "server_key" {
}

variable "server_cert" {
}

locals {
  bucket_key = "fluentd-${md5(data.template_file.certs_user_data.rendered)}-user-data.yml"
}

module "ports" {
  source = "../../../../modules/syslog_ports"
}

data "template_file" "td_agent_configuration" {
  template = file("${path.module}/td-agent.tpl")

  vars = {
    syslog_port                     = module.ports.syslog_port
    s3_logs_bucket                  = var.s3_logs_bucket
    region                          = var.region
    cloudwatch_audit_log_group_name = var.cloudwatch_audit_log_group_name
    cloudwatch_log_group_name       = var.cloudwatch_log_group_name
    cloudwatch_log_stream_name      = var.cloudwatch_log_stream_name
    s3_audit_logs_bucket            = var.s3_audit_logs_bucket
    s3_path                         = var.s3_path

    loki_url      = var.loki_url
    loki_username = var.loki_username
    loki_password = var.loki_password
  }
}

data "template_file" "config_user_data" {
  template = file("${path.module}/user_data.tpl")

  vars = {
    td_agent_configuration = data.template_file.td_agent_configuration.rendered

    region             = var.region
    public_bucket_name = var.public_bucket_name
    fluentd_bundle_key = var.fluentd_bundle_key
  }
}

data "template_file" "certs_user_data" {
  template = file("${path.module}/certs.tpl")

  vars = {
    ca_cert     = var.ca_cert
    server_key  = var.server_key
    server_cert = var.server_cert
  }
}

resource "aws_s3_bucket_object" "certs_user_data" {
  bucket  = var.public_bucket_name
  key     = local.bucket_key
  content = data.template_file.certs_user_data.rendered
}

output "config_user_data" {
  value     = data.template_file.config_user_data.rendered
  sensitive = true
}

output "certs_user_data" {
  value = <<EOF
#include
${var.public_bucket_url}/${local.bucket_key}
EOF

}

