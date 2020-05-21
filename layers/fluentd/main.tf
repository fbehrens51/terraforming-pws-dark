terraform {
  backend "s3" {
  }
}

provider "aws" {
}

variable "remote_state_region" {
}

variable "remote_state_bucket" {
}

variable "tags" {
  type = map(string)
}

variable "internetless" {
}

variable "instance_type" {
  default = "t2.medium"
}

variable "fluentd_bundle_key" {
  description = "Fluentd bundle S3 object key, aka filename."
}

variable "region" {
}

module "providers" {
  source = "../../modules/dark_providers"
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

data "terraform_remote_state" "bastion" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bastion"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_fluentd" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_fluentd"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "encrypt_amis" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "encrypt_amis"
    region  = var.remote_state_region
    encrypt = true
  }
}

locals {
  env_name      = var.tags["Name"]
  modified_name = "${local.env_name} fluentd"
  modified_tags = merge(
    var.tags,
    {
      "Name"       = local.modified_name,
      "MetricsKey" = data.terraform_remote_state.paperwork.outputs.metrics_key,
    },
  )

  log_group_name  = data.terraform_remote_state.bootstrap_fluentd.outputs.log_group_name
  log_stream_name = "fluentd_syslog"

  encrypted_amazon2_ami_id = data.terraform_remote_state.encrypt_amis.outputs.encrypted_amazon2_ami_id

  fluentd_eip_ips = data.terraform_remote_state.bootstrap_fluentd.outputs.fluentd_eip_ips

  root_domain = data.terraform_remote_state.paperwork.outputs.root_domain
}

data "aws_vpc" "es_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.es_vpc_id
}

data "aws_vpc" "pas_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
}


module "configuration" {
  source = "./modules/config"

  root_domain = local.root_domain

  public_bucket_name = data.terraform_remote_state.paperwork.outputs.public_bucket_name
  public_bucket_url  = data.terraform_remote_state.paperwork.outputs.public_bucket_url

  ca_cert     = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs
  server_cert = data.terraform_remote_state.paperwork.outputs.fluentd_server_cert
  server_key  = data.terraform_remote_state.paperwork.outputs.fluentd_server_key

  fluentd_bundle_key = var.fluentd_bundle_key

  cloudwatch_log_group_name  = local.log_group_name
  cloudwatch_log_stream_name = local.log_stream_name
  s3_logs_bucket             = data.terraform_remote_state.bootstrap_fluentd.outputs.s3_bucket_syslog_archive
  s3_audit_logs_bucket       = data.terraform_remote_state.bootstrap_fluentd.outputs.s3_bucket_syslog_audit_archive
  region                     = var.region
  s3_path                    = "logs/"
}

data "template_cloudinit_config" "user_data" {
  base64_encode = true
  gzip          = true

  part {
    filename     = "syslog.cfg"
    content      = module.syslog_config.user_data
    content_type = "text/x-include-url"
  }

  part {
    filename     = "certs.cfg"
    content      = module.configuration.certs_user_data
    content_type = "text/x-include-url"
  }

  part {
    filename     = "config.cfg"
    content_type = "text/cloud-config"
    content      = module.configuration.config_user_data
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "clamav.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.amazon2_clamav_user_data
  }

  part {
    filename     = "node_exporter.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.node_exporter_user_data
  }

  part {
    filename     = "user_accounts_user_data.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.bot_user_accounts_user_data
  }

  part {
    filename     = "banner.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.custom_banner_user_data
  }
}

module "fluentd_instance" {
  instance_count       = 1
  source               = "../../modules/launch"
  instance_type        = var.instance_type
  ami_id               = local.encrypted_amazon2_ami_id
  user_data            = data.template_cloudinit_config.user_data.rendered
  eni_ids              = data.terraform_remote_state.bootstrap_fluentd.outputs.fluentd_eni_ids
  tags                 = local.modified_tags
  check_cloud_init     = false
  bot_key_pem          = data.terraform_remote_state.paperwork.outputs.bot_private_key
  bastion_host         = var.internetless ? null : data.terraform_remote_state.bastion.outputs.bastion_ip
  iam_instance_profile = data.terraform_remote_state.paperwork.outputs.fluentd_role_name
  volume_ids           = [data.terraform_remote_state.bootstrap_fluentd.outputs.volume_id]
}

module "syslog_config" {
  source         = "../../modules/syslog"
  root_domain    = local.root_domain
  syslog_ca_cert = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs

  role_name          = "fluentd"
  public_bucket_name = data.terraform_remote_state.paperwork.outputs.public_bucket_name
  public_bucket_url  = data.terraform_remote_state.paperwork.outputs.public_bucket_url
}

