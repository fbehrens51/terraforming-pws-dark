terraform {
  backend "s3" {
  }
}

provider "aws" {
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

data "terraform_remote_state" "scaling-params" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "scaling-params"
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

data "terraform_remote_state" "bootstrap_postfix" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_postfix"
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
  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} postfix"
  modified_tags = merge(
    var.global_vars["global_tags"],
    var.global_vars["instance_tags"],
    {
      "Name"       = local.modified_name
      "MetricsKey" = data.terraform_remote_state.paperwork.outputs.metrics_key,
      "job"        = "postfix",
    },
  )

  encrypted_amazon2_ami_id = data.terraform_remote_state.encrypt_amis.outputs.encrypted_amazon2_ami_id

  root_domain = data.terraform_remote_state.paperwork.outputs.root_domain

  postfix_ip          = data.terraform_remote_state.bootstrap_postfix.outputs.postfix_eni_ips[0]
  smtp_user           = data.terraform_remote_state.bootstrap_postfix.outputs.smtp_client_user
  smtp_pass           = data.terraform_remote_state.bootstrap_postfix.outputs.smtp_client_password
  bot_user_on_bastion = data.terraform_remote_state.bastion.outputs.bot_user_on_bastion
}

module "configuration" {
  source = "./modules/config"

  public_bucket_name  = data.terraform_remote_state.paperwork.outputs.public_bucket_name
  public_bucket_url   = data.terraform_remote_state.paperwork.outputs.public_bucket_url
  smtp_relay_host     = var.smtp_relay_host
  smtp_relay_port     = data.terraform_remote_state.bootstrap_postfix.outputs.smtp_relay_port
  smtp_relay_username = var.smtp_relay_username
  smtp_relay_password = data.terraform_remote_state.paperwork.outputs.smtp_relay_password
  smtp_relay_ca_cert  = data.terraform_remote_state.paperwork.outputs.smtp_relay_ca_cert
  smtpd_server_cert   = data.terraform_remote_state.paperwork.outputs.smtpd_server_cert
  smtpd_server_key    = data.terraform_remote_state.paperwork.outputs.smtpd_server_key
  smtpd_cidr_blocks   = [data.aws_vpc.es_vpc.cidr_block, data.aws_vpc.pas_vpc.cidr_block]
  smtp_user           = local.smtp_user
  smtp_pass           = local.smtp_pass
  root_domain         = local.root_domain
}

data "aws_vpc" "es_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.es_vpc_id
}

data "aws_vpc" "pas_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
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
    filename     = "system_certs.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.amazon2_system_certs_user_data
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

module "postfix_master_host" {
  instance_count = 1
  source         = "../../modules/launch"
  instance_types       = data.terraform_remote_state.scaling-params.outputs.instance_types
  scale_vpc_key        = "enterprise-services"
  scale_service_key    = "postfix"
  ami_id         = local.encrypted_amazon2_ami_id
  user_data      = data.template_cloudinit_config.user_data.rendered
  eni_ids        = data.terraform_remote_state.bootstrap_postfix.outputs.postfix_eni_ids
  tags           = local.modified_tags
  bot_key_pem    = data.terraform_remote_state.paperwork.outputs.bot_private_key
  bastion_host   = local.bot_user_on_bastion ? data.terraform_remote_state.bastion.outputs.bastion_ip : null
}

module "syslog_config" {
  source         = "../../modules/syslog"
  root_domain    = local.root_domain
  syslog_ca_cert = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs

  role_name          = "postfix"
  public_bucket_name = data.terraform_remote_state.paperwork.outputs.public_bucket_name
  public_bucket_url  = data.terraform_remote_state.paperwork.outputs.public_bucket_url
}

