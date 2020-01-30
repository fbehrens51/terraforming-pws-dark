terraform {
  backend "s3" {
  }
}

data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "paperwork"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "pas" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "pas"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_control_plane" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_control_plane"
    region  = var.remote_state_region
    encrypt = true
  }
}

module "providers" {
  source = "../../modules/dark_providers"
}

locals {
  mirror_bucket   = data.terraform_remote_state.bootstrap_control_plane.outputs.mirror_bucket_name
  hyphenated_name = lower(replace(var.name, " ", "-"))
  base_tile_path  = "${data.aws_s3_bucket_object.base_tile.bucket}/${data.aws_s3_bucket_object.base_tile.key}"
  copied_tile_path = replace(
    basename(local.base_tile_path),
    "p-isolation-segment",
    "p-isolation-segment-${local.hyphenated_name}",
  )
}

module "domains" {
  source = "../../modules/domains"

  root_domain = data.terraform_remote_state.paperwork.outputs.root_domain
}

module "splunk_ports" {
  source = "../../modules/splunk_ports"
}

module "config" {
  source = "../../modules/isolation_segment_config"

  iso_seg_tile_suffix = local.hyphenated_name
  mirror_bucket       = local.mirror_bucket

  pivnet_api_token     = var.pivnet_api_token
  s3_access_key_id     = var.s3_access_key_id
  s3_secret_access_key = var.s3_secret_access_key
  s3_auth_type         = var.s3_auth_type
  s3_endpoint          = var.s3_endpoint
  region               = var.region

  vanity_cert_enabled    = var.vanity_cert_enabled
  vanity_cert_pem        = data.terraform_remote_state.paperwork.outputs.vanity_server_cert
  vanity_private_key_pem = data.terraform_remote_state.paperwork.outputs.vanity_server_key

  router_cert_pem                = data.terraform_remote_state.paperwork.outputs.router_server_cert
  router_private_key_pem         = data.terraform_remote_state.paperwork.outputs.router_server_key
  router_trusted_ca_certificates = data.terraform_remote_state.paperwork.outputs.router_trusted_ca_certs

  pas_subnet_availability_zones = data.terraform_remote_state.pas.outputs.pas_subnet_availability_zones
  singleton_availability_zone   = var.singleton_availability_zone

  splunk_syslog_host    = module.domains.splunk_logs_fqdn
  splunk_syslog_port    = module.splunk_ports.splunk_tcp_port
  splunk_syslog_ca_cert = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs
}

data "aws_s3_bucket_object" "base_tile" {
  bucket = local.mirror_bucket
  key    = "[p-isolation-segment,${module.config.product_version}]p-isolation-segment-${module.config.file_version}.pivotal"
}

resource "null_resource" "replicator" {
  triggers = {
    script_md5     = filemd5("${path.module}/replicate-iso-segment.sh")
    base_tile_name = var.name
    base_tile_etag = data.aws_s3_bucket_object.base_tile.etag
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/replicate-iso-segment.sh ${local.base_tile_path} \"${var.name}\" ${local.copied_tile_path}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "aws s3 rm s3://${local.mirror_bucket}/${local.copied_tile_path}"
  }
}

