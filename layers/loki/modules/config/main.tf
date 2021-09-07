
module "ports" {
  source = "../../../../modules/syslog_ports"
}

data "template_file" "config_user_data" {
  template = file("${path.module}/user_data.tpl")

  vars = {
    loki_configuration = local.loki_configuration

    region             = var.region
    public_bucket_name = var.public_bucket_name
    loki_location      = local.loki_location
  }
}

locals {
  bucket_key    = "loki-${md5(data.template_file.config_user_data.rendered)}-user-data.yml"
  loki_location = "${var.public_bucket_url}/${var.loki_bundle_key}"
  loki_configuration = templatefile("${path.module}/loki.yaml", {
    http_port      = module.ports.loki_http_port
    grpc_port      = module.ports.loki_grpc_port
    region         = var.region
    loki_ips       = var.loki_ips
    storage_bucket = var.storage_bucket
  })
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

