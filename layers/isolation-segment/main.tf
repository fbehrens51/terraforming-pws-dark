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

data "terraform_remote_state" "scaling-params" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "scaling-params"
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

locals {
  secrets_bucket_name = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
  hyphenated_name     = lower(replace(var.name, " ", "-"))
}

module "domains" {
  source = "../../modules/domains"

  root_domain = data.terraform_remote_state.paperwork.outputs.root_domain
}

module "syslog_ports" {
  source = "../../modules/syslog_ports"
}

module "config" {
  source = "../../modules/isolation_segment_config"

  scale                    = data.terraform_remote_state.scaling-params.outputs.instance_types
  iso_seg_name             = var.name
  iso_seg_tile_suffix      = local.hyphenated_name
  secrets_bucket_name      = local.secrets_bucket_name
  isolation_segment_config = "pas/${lower(replace(var.name, " ", "_"))}_isolation_segment_config.yml"

  vanity_cert_enabled    = var.vanity_cert_enabled
  vanity_cert_pem        = data.terraform_remote_state.paperwork.outputs.vanity_server_cert
  vanity_private_key_pem = data.terraform_remote_state.paperwork.outputs.vanity_server_key

  router_cert_pem                = data.terraform_remote_state.paperwork.outputs.router_server_cert
  router_private_key_pem         = data.terraform_remote_state.paperwork.outputs.router_server_key
  router_trusted_ca_certificates = data.terraform_remote_state.paperwork.outputs.router_trusted_ca_certs_bundle

  pas_subnet_availability_zones = data.terraform_remote_state.pas.outputs.pas_subnet_availability_zones
  singleton_availability_zone   = var.singleton_availability_zone

  syslog_host    = module.domains.fluentd_fqdn
  syslog_port    = module.syslog_ports.syslog_port
  syslog_ca_cert = data.terraform_remote_state.paperwork.outputs.syslog_ca_certs_bundle

  env_name = var.global_vars.env_name
}
