variable "secrets_bucket_name" {
}

variable "root_domain" {
}

module "domains" {
  source = "../domains"

  root_domain = var.root_domain
}

locals {
  bucket_key = "cf-events-logger-config/config.yml"
}

data "template_file" "app-manifest" {
  template = <<EOF
applications:
- name: cf-events-logger
  buildpacks:
  - binary_buildpack
  disk_quota: 1G
  env:
    CF_API_URL: https://api.${module.domains.system_fqdn}
  instances: 1
  memory: 1G
  stack: cflinuxfs3
EOF

}

resource "aws_s3_bucket_object" "app-manifest" {
  bucket  = var.secrets_bucket_name
  key     = local.bucket_key
  content = data.template_file.app-manifest.rendered
}

