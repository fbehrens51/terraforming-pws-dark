
module "ports" {
  source = "../../../../modules/syslog_ports"
}

data "template_file" "loki_configuration" {
  template = file("${path.module}/loki.yaml")

  vars = {
    http_port = module.ports.loki_http_port
    grpc_port = module.ports.loki_grpc_port
    region    = var.region
  }
}

data "template_file" "config_user_data" {
  template = file("${path.module}/user_data.tpl")

  vars = {
    loki_configuration = data.template_file.loki_configuration.rendered

    region             = var.region
    public_bucket_name = var.public_bucket_name
    loki_bundle_key    = local.loki_location
  }
}

locals {
  bucket_key    = "loki-${md5(data.template_file.config_user_data.rendered)}-user-data.yml"
  loki_location = "${var.public_bucket_url}/${var.loki_bundle_key}"
}

resource "aws_s3_bucket_object" "config_user_data" {
  bucket  = var.public_bucket_name
  key     = local.bucket_key
  content = data.template_file.config_user_data.rendered
}

output "config_user_data" {
  value = <<EOF
#include
${var.public_bucket_url}/${local.bucket_key}
EOF

}

