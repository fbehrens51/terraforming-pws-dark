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

data "terraform_remote_state" "bootstrap_control_plane" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_control_plane"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_control_plane_foundation" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_control_plane_foundation"
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

data "terraform_remote_state" "bootstrap_postfix" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_postfix"
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

data "terraform_remote_state" "bootstrap_loki" {
  count   = var.enable_loki ? 1 : 0
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_loki"
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

data "aws_vpc" "es_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.es_vpc_id
}

locals {
  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} bind"
  modified_tags = merge(
    var.global_vars["global_tags"],
    var.global_vars["instance_tags"],
    {
      "Name"            = local.modified_name
      "MetricsKey"      = data.terraform_remote_state.paperwork.outputs.metrics_key,
      "foundation_name" = data.terraform_remote_state.paperwork.outputs.foundation_name
      "job"             = "bind",
    },
  )

  root_domain = data.terraform_remote_state.paperwork.outputs.root_domain

  // If internetless = true in the bootstrap_bind layer,
  // eip_ips will be empty, and master_public_ip becomes the first eni_ip
  public_ips  = data.terraform_remote_state.bootstrap_bind.outputs.bind_eip_ips
  private_ips = data.terraform_remote_state.bootstrap_bind.outputs.bind_eni_ips
  master_ips  = length(local.public_ips) > 0 ? local.public_ips : local.private_ips

  encrypted_amazon2_ami_id = data.terraform_remote_state.paperwork.outputs.amzn_ami_id

  om_public_ip                = data.terraform_remote_state.pas.outputs.ops_manager_ip
  control_plane_om_public_ip  = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.ops_manager_ip
  control_plane_plane_elb_dns = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.plane_elb_dns
  pas_elb_dns                 = data.terraform_remote_state.pas.outputs.pas_elb_dns_name
  postfix_private_ip          = data.terraform_remote_state.bootstrap_postfix.outputs.postfix_eni_ips[0]
  fluentd_dns_name            = data.terraform_remote_state.bootstrap_fluentd.outputs.fluentd_lb_dns_name
  loki_config = var.enable_loki ? {
    enabled       = true
    loki_dns_name = data.terraform_remote_state.bootstrap_loki[0].outputs.loki_lb_dns_name
    } : {
    enabled       = false
    loki_dns_name = ""
  }
  grafana_elb_dns                     = data.terraform_remote_state.pas.outputs.grafana_elb_dns_name
  control_plane_plane_uaa_elb_dns     = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.uaa_elb_dns
  control_plane_plane_credhub_elb_dns = data.terraform_remote_state.bootstrap_control_plane_foundation.outputs.credhub_elb_dns
}

data "template_cloudinit_config" "master_bind_conf_userdata" {
  base64_encode = true
  gzip          = true

  part {
    filename     = "tag_completion.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.completion_tag_user_data
  }

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
    filename     = "bind_exporter.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.bind_exporter_user_data
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

  part {
    filename     = "iptables.cfg"
    content_type = "text/cloud-config"
    content      = module.iptables_rules.iptables_user_data
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "dnsmasq.cfg"
    content_type = "text/cloud-config"
    content      = module.dnsmasq.dnsmasq_user_data
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "postfix_client.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.postfix_client_user_data
  }

  # This must be last - updates the AIDE DB after all installations/configurations are complete.
  part {
    filename     = "hardening.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.server_hardening_user_data
  }
}

module "dnsmasq" {
  source         = "../../modules/dnsmasq"
  enterprise_dns = data.terraform_remote_state.paperwork.outputs.enterprise_dns
  forwarders = [{
    domain        = data.terraform_remote_state.paperwork.outputs.endpoint_domain
    forwarder_ips = [cidrhost(data.aws_vpc.es_vpc.cidr_block, 2)]
    },
    {
      domain        = ""
      forwarder_ips = data.terraform_remote_state.paperwork.outputs.enterprise_dns
    }
  ]
}

module "iptables_rules" {
  source = "../../modules/iptables"
  // block the DNS Amplification Attacks
  internet_only_rules = var.internet == false ? [] : [
    "# DNSKEY records",
    "iptables -A INPUT -p udp --dport 53 -m string --hex-string \"|00003000|\"   --algo bm --from 40 -j DROP",
    "iptables -A INPUT -p tcp --dport 53 -m string --hex-string \"|00003000|\"   --algo bm --from 52 -j DROP",
    "# RRSIG records",
    "iptables -A INPUT -p udp --dport 53 -m string --hex-string \"|00002E00|\"   --algo bm --from 40 -j DROP",
    "iptables -A INPUT -p tcp --dport 53 -m string --hex-string \"|00002E00|\"   --algo bm --from 52 -j DROP",
    "# ref: https://forums.centos.org/viewtopic.php?f=51&t=62148&sid=3687bf227875a582ba08964fca178dd2",
    "iptables -A INPUT -p udp --dport 53 -m string --hex-string \"|0000FF0001|\" --algo bm --from 40 -j DROP",
    "iptables -A INPUT -p tcp --dport 53 -m string --hex-string \"|0000FF0001|\" --algo bm --from 52 -j DROP"
  ]
  personality_rules = [
    "iptables -A INPUT -p tcp --dport 53 -m state --state NEW -j ACCEPT",
    "iptables -A INPUT -p udp --dport 53 -m state --state NEW -j ACCEPT",
    "iptables -A INPUT -p tcp --dport 9119 -m state --state NEW -j ACCEPT"
  ]
  control_plane_subnet_cidrs = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_cidrs
}

module "bind_master_user_data" {
  source      = "../../modules/bind_dns/user_data"
  client_cidr = var.client_cidr
  master_ips  = local.master_ips
  zone_name   = local.root_domain

  om_public_ip                        = local.om_public_ip
  control_plane_om_public_ip          = local.control_plane_om_public_ip
  control_plane_plane_elb_dns         = local.control_plane_plane_elb_dns
  pas_elb_dns                         = local.pas_elb_dns
  postfix_private_ip                  = local.postfix_private_ip
  fluentd_dns_name                    = local.fluentd_dns_name
  loki_config                         = local.loki_config
  grafana_elb_dns                     = local.grafana_elb_dns
  control_plane_plane_uaa_elb_dns     = local.control_plane_plane_uaa_elb_dns
  control_plane_plane_credhub_elb_dns = local.control_plane_plane_credhub_elb_dns
}

module "bind_master_host" {
  instance_count       = 3
  source               = "../../modules/launch"
  instance_types       = data.terraform_remote_state.scaling-params.outputs.instance_types
  scale_vpc_key        = "enterprise-services"
  scale_service_key    = "bind"
  ami_id               = local.encrypted_amazon2_ami_id
  user_data            = data.template_cloudinit_config.master_bind_conf_userdata.rendered
  eni_ids              = data.terraform_remote_state.bootstrap_bind.outputs.bind_eni_ids
  tags                 = local.modified_tags
  bot_key_pem          = data.terraform_remote_state.paperwork.outputs.bot_private_key
  iam_instance_profile = data.terraform_remote_state.paperwork.outputs.instance_tagger_role_name
}

module "syslog_config" {
  source         = "../../modules/syslog"
  root_domain    = local.root_domain
  syslog_ca_cert = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs

  role_name          = "bind"
  public_bucket_name = data.terraform_remote_state.paperwork.outputs.public_bucket_name
  public_bucket_url  = data.terraform_remote_state.paperwork.outputs.public_bucket_url
}

variable "remote_state_region" {
}

variable "remote_state_bucket" {
}

variable "global_vars" {
  type = any
}

variable "client_cidr" {
}

variable "internetless" {
}

variable "internet" {
  default     = false
  description = "if true, applies extra rules to iptables on the bind servers to prevent participation in distributed DNS amplification attacks"
}

variable "enable_loki" {
  type    = bool
  default = false
}

output "master_ips" {
  value = local.master_ips
}

output "ssh_host_ips" {
  value = zipmap(flatten(module.bind_master_host.ssh_host_names), flatten(module.bind_master_host.private_ips))
}
