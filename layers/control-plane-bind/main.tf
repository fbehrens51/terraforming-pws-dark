provider "aws" {
}

module "providers" {
  source = "../../modules/dark_providers"
}

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

data "terraform_remote_state" "bootstrap_control_plane" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_control_plane"
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


data "aws_vpc" "vpc" {
  id = data.terraform_remote_state.paperwork.outputs.cp_vpc_id
}

data "aws_vpc" "pas_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
}

locals {

  env_name              = var.global_vars.env_name
  cp_bind_modified_name = "${local.env_name} control-plane bind"
  cp_bind_modified_tags = merge(
    var.global_vars["global_tags"],
    var.global_vars["instance_tags"],
    {
      "Name"       = local.cp_bind_modified_name
      "MetricsKey" = data.terraform_remote_state.paperwork.outputs.metrics_key,
      "job"        = "cp_bind"
    },
  )

  cp_bind_ingress_rules = [
    {
      description = "Allow ssh/22 from cp_vpc"
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = data.aws_vpc.vpc.cidr_block
    },
    {
      description = "Allow dns/53 from everywhere"
      port        = "53"
      protocol    = "tcp"
      cidr_blocks = data.aws_vpc.vpc.cidr_block
    },
    {
      description = "Allow dns/53 from everywhere"
      port        = "53"
      protocol    = "udp"
      cidr_blocks = data.aws_vpc.vpc.cidr_block
    },
    {
      description = "Allow node_exporter/9100 from pas_vpc"
      port        = "9100"
      protocol    = "tcp"
      cidr_blocks = data.aws_vpc.pas_vpc.cidr_block
    },
  ]
  cp_bind_egress_rules = [
    {
      description = "Allow all portocols/ports to everywhere"
      port        = "0"
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}
module "bind_eni" {
  source        = "../../modules/eni_per_subnet"
  ingress_rules = local.cp_bind_ingress_rules
  egress_rules  = local.cp_bind_egress_rules
  subnet_ids    = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_public_subnet_ids
  eni_count     = 3
  create_eip    = ! var.internetless
  tags          = local.cp_bind_modified_tags
}


module "cp_dns_forwarder" {
  source      = "../../modules/bind_dns/cp_forwarder"
  client_cidr = data.aws_vpc.vpc.cidr_block
  master_ips  = module.bind_eni.eni_ips
  forwarders = [{
    domain        = var.endpoint_domain
    forwarder_ips = [cidrhost(data.aws_vpc.vpc.cidr_block, 2)]
    },
    {
      domain        = ""
      forwarder_ips = data.terraform_remote_state.paperwork.outputs.enterprise_dns
    }
  ]
}

data "template_cloudinit_config" "master_cp_bind_conf_userdata" {
  base64_encode = true
  gzip          = true

  part {
    filename     = "cp_master_bind_conf.cfg"
    content_type = "text/cloud-config"
    content      = module.cp_dns_forwarder.user_data
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "syslog.cfg"
    content      = module.syslog_config.user_data
    content_type = "text/x-include-url"
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
    filename     = "tag_completion.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.completion_tag_user_data
  }
  part {
    filename     = "iptables.cfg"
    content_type = "text/cloud-config"
    content      = module.iptables_rules.iptables_user_data
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

module "iptables_rules" {
  source = "../../modules/iptables"
  // block the DNS Amplification Attacks
  internet_only_rules = var.internet == false ? [] : [
    "# ref: https://forums.centos.org/viewtopic.php?f=51&t=62148&sid=3687bf227875a582ba08964fca178dd2",
    "iptables -A INPUT -p udp --dport 53 -m string --hex-string \"|0000FF0001|\" --algo bm --from 40 -j DROP",
    "iptables -A INPUT -p tcp --dport 53 -m string --hex-string \"|0000FF0001|\" --algo bm --from 52 -j DROP"
  ]
  personality_rules = [
    "iptables -A INPUT -p tcp --dport 53 -m state --state NEW -j ACCEPT",
    "iptables -A INPUT -p udp --dport 53 -m state --state NEW -j ACCEPT"
  ]
  control_plane_subnet_cidrs = [data.aws_vpc.vpc.cidr_block]
}

module "cp_bind_master_host" {
  instance_count       = 3
  source               = "../../modules/launch"
  instance_types       = data.terraform_remote_state.scaling-params.outputs.instance_types
  scale_vpc_key        = "control-plane"
  scale_service_key    = "bind"
  ami_id               = data.terraform_remote_state.paperwork.outputs.amzn_ami_id
  user_data            = data.template_cloudinit_config.master_cp_bind_conf_userdata.rendered
  eni_ids              = module.bind_eni.eni_ids
  tags                 = local.cp_bind_modified_tags
  bot_key_pem          = data.terraform_remote_state.paperwork.outputs.bot_private_key
  iam_instance_profile = data.terraform_remote_state.paperwork.outputs.instance_tagger_role_name
}


module "syslog_config" {
  source         = "../../modules/syslog"
  root_domain    = data.terraform_remote_state.paperwork.outputs.root_domain
  syslog_ca_cert = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs

  role_name          = "cp_bind"
  public_bucket_name = data.terraform_remote_state.paperwork.outputs.public_bucket_name
  public_bucket_url  = data.terraform_remote_state.paperwork.outputs.public_bucket_url
}

//resource "aws_vpc_dhcp_options" "cp_dhcp_options" {
//  domain_name_servers = data.terraform_remote_state.paperwork.outputs.enterprise_dns
//  //  ntp_servers = []
//  tags = {
//    name = "CP DHCP Options"
//  }
//}
//
//resource "aws_vpc_dhcp_options_association" "cp_dhcp_options_assoc" {
//  dhcp_options_id = aws_vpc_dhcp_options.cp_dhcp_options.id
//  vpc_id          = data.aws_vpc.vpc.id
//  depends_on      = [aws_vpc_dhcp_options.cp_dhcp_options]
//}

