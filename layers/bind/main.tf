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

data "terraform_remote_state" "bastion" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bastion"
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

data "terraform_remote_state" "pas" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "pas"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_splunk" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_splunk"
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

data "terraform_remote_state" "bootstrap_bind" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_bind"
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
  modified_name = "${local.env_name} bind"
  modified_tags = merge(
    var.tags,
    {
      "Name" = local.modified_name
      "ScrapeMetrics" = "true"
    },
  )

  root_domain = data.terraform_remote_state.paperwork.outputs.root_domain

  // If internetless = true in the bootstrap_bind layer,
  // eip_ips will be empty, and master_public_ip becomes the first eni_ip
  public_ips  = data.terraform_remote_state.bootstrap_bind.outputs.bind_eip_ips
  private_ips = data.terraform_remote_state.bootstrap_bind.outputs.bind_eni_ips
  master_ips  = length(local.public_ips) > 0 ? local.public_ips : local.private_ips

  encrypted_amazon2_ami_id = data.terraform_remote_state.encrypt_amis.outputs.encrypted_amazon2_ami_id

  om_public_ip                = data.terraform_remote_state.pas.outputs.ops_manager_ip
  control_plane_om_public_ip  = data.terraform_remote_state.bootstrap_control_plane.outputs.ops_manager_ip
  control_plane_plane_elb_dns = data.terraform_remote_state.bootstrap_control_plane.outputs.plane_elb_dns
  pas_elb_dns                 = data.terraform_remote_state.pas.outputs.pas_elb_dns_name
  postfix_private_ip          = data.terraform_remote_state.bootstrap_postfix.outputs.postfix_eni_ips[0]
  splunk_logs_private_ip      = data.terraform_remote_state.bootstrap_splunk.outputs.forwarders_private_ips[0]
  splunk_search_head_elb_dns  = data.terraform_remote_state.bootstrap_splunk.outputs.splunk_search_head_elb_dns_name
  splunk_monitor_elb_dns      = data.terraform_remote_state.bootstrap_splunk.outputs.splunk_monitor_elb_dns_name
  grafana_elb_dns             = data.terraform_remote_state.pas.outputs.grafana_elb_dns_name
}

data "template_cloudinit_config" "master_bind_conf_userdata" {
  base64_encode = true
  gzip          = true

  part {
    filename     = "syslog.cfg"
    content      = module.syslog_config.user_data
    content_type = "text/x-include-url"
  }

  part {
    filename     = "master_bind_conf.cfg"
    content_type = "text/cloud-config"
    content      = module.bind_master_user_data.user_data
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

module "bind_master_user_data" {
  source      = "../../modules/bind_dns/user_data"
  client_cidr = var.client_cidr
  master_ips  = local.master_ips
  zone_name   = local.root_domain

  om_public_ip                = local.om_public_ip
  control_plane_om_public_ip  = local.control_plane_om_public_ip
  control_plane_plane_elb_dns = local.control_plane_plane_elb_dns
  pas_elb_dns                 = local.pas_elb_dns
  postfix_private_ip          = local.postfix_private_ip
  splunk_search_head_elb_dns  = local.splunk_search_head_elb_dns
  splunk_logs_private_ip      = local.splunk_logs_private_ip
  splunk_monitor_elb_dns      = local.splunk_monitor_elb_dns
  grafana_elb_dns             = local.grafana_elb_dns
}

module "bind_master_host" {
  instance_count = 3
  source         = "../../modules/launch"
  instance_type  = "t2.medium"
  ami_id         = local.encrypted_amazon2_ami_id
  user_data      = data.template_cloudinit_config.master_bind_conf_userdata.rendered
  eni_ids        = data.terraform_remote_state.bootstrap_bind.outputs.bind_eni_ids
  tags           = local.modified_tags
  bot_key_pem    = data.terraform_remote_state.paperwork.outputs.bot_private_key
  bastion_host   = var.internetless ? null : data.terraform_remote_state.bastion.outputs.bastion_ip
}

module "syslog_config" {
  source                = "../../modules/syslog"
  root_domain           = local.root_domain
  splunk_syslog_ca_cert = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs

  role_name          = "bind"
  public_bucket_name = data.terraform_remote_state.paperwork.outputs.public_bucket_name
  public_bucket_url  = data.terraform_remote_state.paperwork.outputs.public_bucket_url
}

variable "remote_state_region" {
}

variable "remote_state_bucket" {
}

variable "tags" {
  type = map(string)
}

variable "client_cidr" {
}

variable "internetless" {
}

output "master_ips" {
  value = local.master_ips
}
