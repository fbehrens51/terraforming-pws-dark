variable "public_bucket_url" {
}

variable "public_bucket_name" {
}

variable "smtp_relay_host" {
}

variable "smtp_relay_port" {
}

variable "smtp_relay_username" {
}

variable "smtp_relay_password" {
}

variable "smtp_relay_ca_cert" {
}

variable "smtpd_server_key" {
}

variable "smtpd_server_cert" {
}

variable "smtpd_cidr_blocks" {
  type = list(string)
}

variable "smtp_user" {
}

variable "smtp_pass" {
}

variable "root_domain" {
}

variable "smtp_from" {
}

variable "smtp_to" {
}

module "domains" {
  source      = "../../../../modules/domains"
  root_domain = var.root_domain
}

locals {
  bucket_key = "postfix-user-data.yml"
}

data "template_file" "config_user_data" {
  template = file("${path.module}/user_data.tpl")

  vars = {
    smtp_relay_host     = var.smtp_relay_host
    smtp_relay_port     = var.smtp_relay_port
    smtp_relay_username = var.smtp_relay_username
    smtp_relay_password = var.smtp_relay_password
    cidr_blocks         = join(" ", var.smtpd_cidr_blocks)
    smtp_user           = var.smtp_user
    smtp_pass           = var.smtp_pass
    root_domain         = var.root_domain
    smtp_fqdn           = module.domains.smtp_fqdn
    smtp_from           = var.smtp_from
    smtp_to             = var.smtp_to
  }
}

data "template_file" "certs_user_data" {
  template = file("${path.module}/certs.tpl")

  vars = {
    smtp_relay_ca_cert = var.smtp_relay_ca_cert
    smtpd_server_key   = var.smtpd_server_key
    smtpd_server_cert  = var.smtpd_server_cert
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
