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

data "terraform_remote_state" "bootstrap_postfix" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_postfix"
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
  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} postfix"
  modified_tags = merge(
    var.global_vars["global_tags"],
    var.global_vars["instance_tags"],
    {
      "Name"            = local.modified_name
      "MetricsKey"      = data.terraform_remote_state.paperwork.outputs.metrics_key,
      "foundation_name" = data.terraform_remote_state.paperwork.outputs.foundation_name
      "job"             = "postfix",
    },
  )

  encrypted_amazon2_ami_id = data.terraform_remote_state.paperwork.outputs.amzn_ami_id

  root_domain = data.terraform_remote_state.paperwork.outputs.root_domain

  postfix_ip = data.terraform_remote_state.bootstrap_postfix.outputs.postfix_eni_ips[0]
  smtp_user  = data.terraform_remote_state.bootstrap_postfix.outputs.smtp_client_user
  smtp_pass  = data.terraform_remote_state.bootstrap_postfix.outputs.smtp_client_password
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
  smtpd_cidr_blocks   = concat([data.aws_vpc.es_vpc.cidr_block, data.aws_vpc.pas_vpc.cidr_block, data.aws_vpc.cp_vpc.cidr_block], [for vpc in data.aws_vpc.iso_vpcs : vpc.cidr_block])
  smtp_user           = local.smtp_user
  smtp_pass           = local.smtp_pass
  root_domain         = local.root_domain
  # smtp_to/from are used to foward local mail (postfix vm) and relayed mail (from other AL2 vms)
  smtp_from = data.terraform_remote_state.paperwork.outputs.smtp_from
  smtp_to   = data.terraform_remote_state.paperwork.outputs.smtp_to
}

data "aws_vpc" "iso_vpcs" {
  for_each = toset(data.terraform_remote_state.paperwork.outputs.iso_vpc_ids)
  id       = each.value
}

data "aws_vpc" "es_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.es_vpc_id
}

data "aws_vpc" "pas_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
}

data "aws_vpc" "cp_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.cp_vpc_id
}

data "template_cloudinit_config" "user_data" {
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
  personality_rules = [
    "iptables -A INPUT -p tcp --dport 25                  -m state --state NEW -j ACCEPT"
  ]
  control_plane_subnet_cidrs = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_cidrs
}

module "postfix_master_host" {
  instance_count       = 1
  source               = "../../modules/launch"
  instance_types       = data.terraform_remote_state.scaling-params.outputs.instance_types
  scale_vpc_key        = "enterprise-services"
  scale_service_key    = "postfix"
  ami_id               = local.encrypted_amazon2_ami_id
  user_data            = data.template_cloudinit_config.user_data.rendered
  eni_ids              = data.terraform_remote_state.bootstrap_postfix.outputs.postfix_eni_ids
  tags                 = local.modified_tags
  bot_key_pem          = data.terraform_remote_state.paperwork.outputs.bot_private_key
  iam_instance_profile = data.terraform_remote_state.paperwork.outputs.instance_tagger_role_name
  operating_system     = data.terraform_remote_state.paperwork.outputs.amazon_operating_system_tag
}

module "syslog_config" {
  source         = "../../modules/syslog"
  root_domain    = local.root_domain
  syslog_ca_cert = data.terraform_remote_state.paperwork.outputs.syslog_ca_certs_bundle

  role_name          = "postfix"
  public_bucket_name = data.terraform_remote_state.paperwork.outputs.public_bucket_name
  public_bucket_url  = data.terraform_remote_state.paperwork.outputs.public_bucket_url
}

output "ssh_host_ips" {
  value = zipmap(flatten(module.postfix_master_host.ssh_host_names), flatten(module.postfix_master_host.private_ips))
}

module "sshconfig" {
  source         = "../../modules/ssh_config"
  foundation_name = data.terraform_remote_state.paperwork.outputs.foundation_name
  host_ips = zipmap(flatten(module.postfix_master_host.ssh_host_names), flatten(module.postfix_master_host.private_ips))
  host_type = "postfix"
  secrets_bucket_name = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
}