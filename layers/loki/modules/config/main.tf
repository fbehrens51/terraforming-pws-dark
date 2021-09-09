
module "ports" {
  source = "../../../../modules/syslog_ports"
}

module "domains" {
  source = "../../../../modules/domains"

  root_domain = var.root_domain
}

data "template_file" "config_user_data" {
  for_each = toset(var.loki_ips)
  template = file("${path.module}/user_data.tpl")

  vars = {
    loki_configuration = local.loki_configuration

    region             = var.region
    public_bucket_name = var.public_bucket_name
    loki_location      = local.loki_location
    http_port          = module.ports.loki_http_port
    local_ip           = each.value
    server_name        = each.value
  }
}

locals {
  bucket_key    = [for i, ip in var.loki_ips : "loki-${i}-${md5(data.template_file.config_user_data.rendered)}-user-data.yml"]
  loki_location = "${var.public_bucket_url}/${var.loki_bundle_key}"
  loki_configuration = templatefile("${path.module}/loki.yaml", {
    bind_port      = module.ports.loki_bind_port
    http_port      = module.ports.loki_http_port
    grpc_port      = module.ports.loki_grpc_port
    region         = var.region
    loki_ips       = var.loki_ips
    storage_bucket = var.storage_bucket
  })
}

resource "aws_s3_bucket_object" "config_user_data" {
  count   = length(var.loki_ips)
  bucket  = var.public_bucket_name
  key     = var.loki_ips[count.index]
  content = data.template_file.config_user_data.rendered
}

output "config_user_data" {
  value = [for i, ip in var.loki_ips : <<EOF
#include
${var.public_bucket_url}/${local.bucket_key[i]}
EOF

  ]

}

