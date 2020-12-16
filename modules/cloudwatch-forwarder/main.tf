variable "secrets_bucket_name" {
}

variable "root_domain" {
}

variable "broker_password" {
}

variable "database_url" {
}

variable "region" {
}

variable "cap_url" {
}

variable "cap_root_ca" {
}

module "domains" {
  source = "../domains"

  root_domain = var.root_domain
}

locals {
  bucket_key = "cloudwatch-log-forwarder-config/config.yml"
}

data "template_file" "app-manifest" {
  template = <<EOF
applications:
- name: cloudwatch-log-forwarder
  buildpacks:
  - binary_buildpack
  disk_quota: 1G
  env:
    AWS_REGION: ${var.region}
    CAP_ROOT_CA: |
      ${indent(6, var.cap_root_ca)}
    CAP_URL: ${var.cap_url}
    CF_API_URL: https://api.${module.domains.system_fqdn}
    BROKER_USERNAME: broker
    BROKER_PASSWORD: ${var.broker_password}
    DATABASE_URL: ${var.database_url}
  instances: 3
  memory: 1G
  stack: cflinuxfs3
EOF

}

resource "aws_s3_bucket_object" "app-manifest" {
  bucket  = var.secrets_bucket_name
  key     = local.bucket_key
  content = data.template_file.app-manifest.rendered
}

