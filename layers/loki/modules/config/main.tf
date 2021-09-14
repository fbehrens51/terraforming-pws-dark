
module "ports" {
  source = "../../../../modules/syslog_ports"
}

module "domains" {
  source = "../../../../modules/domains"

  root_domain = var.root_domain
}

locals {
  bucket_key    = [for i, ip in var.loki_ips : "loki-${i}-${md5(local.config_user_data[i])}-user-data.yml"]
  loki_location = "${var.public_bucket_url}/${var.loki_bundle_key}"

  config_user_data = [for i, ip in var.loki_ips : templatefile("${path.module}/user_data.tpl", {
    ca_cert     = var.ca_cert
    server_key  = var.server_key
    server_cert = var.server_cert

    loki_configuration = local.loki_configuration
    nginx_http         = local.nginx_http[i]
    nginx_grpc         = local.nginx_grpc[i]
    nginx_gossip       = local.nginx_gossip[i]

    region             = var.region
    public_bucket_name = var.public_bucket_name
    loki_location      = local.loki_location
    healthcheck_port   = module.ports.loki_healthcheck_port
    http_port          = module.ports.loki_http_port
    grpc_port          = module.ports.loki_grpc_port
    local_ip           = ip
    loki_ips           = var.loki_ips
    server_name        = module.domains.loki_fqdn
  })]

  nginx_http = [for i, ip in var.loki_ips : templatefile("${path.module}/nginx-http.conf", {
    loki_configuration = local.loki_configuration

    region             = var.region
    public_bucket_name = var.public_bucket_name
    loki_location      = local.loki_location
    http_port          = module.ports.loki_http_port
    grpc_port          = module.ports.loki_grpc_port
    local_ip           = ip
    loki_ips           = var.loki_ips
    server_name        = module.domains.loki_fqdn
  })]

  nginx_grpc = [for i, ip in var.loki_ips : templatefile("${path.module}/nginx-grpc.conf", {
    loki_configuration = local.loki_configuration

    region             = var.region
    public_bucket_name = var.public_bucket_name
    loki_location      = local.loki_location
    http_port          = module.ports.loki_http_port
    grpc_port          = module.ports.loki_grpc_port
    local_ip           = ip
    loki_ips           = var.loki_ips
    server_name        = module.domains.loki_fqdn
  })]

  nginx_gossip = [for i, ip in var.loki_ips : templatefile("${path.module}/nginx-gossip.conf", {
    loki_configuration = local.loki_configuration

    region             = var.region
    public_bucket_name = var.public_bucket_name
    loki_location      = local.loki_location
    http_port          = module.ports.loki_http_port
    grpc_port          = module.ports.loki_grpc_port
    bind_port          = module.ports.loki_bind_port
    local_ip           = ip
    loki_ips           = var.loki_ips
    server_name        = module.domains.loki_fqdn
  })]

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
  key     = local.bucket_key[count.index]
  content = local.config_user_data[count.index]
}

output "config_user_data" {
  value = [for i, ip in var.loki_ips : <<EOF
#include
${var.public_bucket_url}/${local.bucket_key[i]}
EOF

  ]

}

