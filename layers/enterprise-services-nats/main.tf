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

data "terraform_remote_state" "es" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_enterprise_services"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "aws_route_tables" "es_private_route_tables" {
  vpc_id = local.es_vpc_id
  tags   = merge(var.global_vars["global_tags"], { "Type" = "PRIVATE" })
}

data "aws_route_table" "es_public_route_table" {
  vpc_id = local.es_vpc_id
  tags   = merge(var.global_vars["global_tags"], { "Type" = "PUBLIC" })
}


locals {
  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} enterprise services"
  modified_tags = merge(
    var.global_vars["global_tags"],
    {
      "Name"            = local.modified_name
      "MetricsKey"      = data.terraform_remote_state.paperwork.outputs.metrics_key,
      "foundation_name" = data.terraform_remote_state.paperwork.outputs.foundation_name
    },
  )

  es_vpc_id  = data.terraform_remote_state.paperwork.outputs.es_vpc_id
  pas_vpc_id = data.terraform_remote_state.paperwork.outputs.pas_vpc_id

}

data "aws_vpc" "this_vpc" {
  id = local.es_vpc_id
}

data "aws_vpc" "pas_vpc" {
  id = local.pas_vpc_id
}

data "template_cloudinit_config" "nat_user_data" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "tag_completion.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.completion_tag_user_data
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
    filename     = "banner.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.custom_banner_user_data
  }

  part {
    filename     = "bot_user_accounts_user_data.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.bot_user_accounts_user_data
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
  source                     = "../../modules/iptables"
  nat                        = true
  control_plane_subnet_cidrs = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_cidrs
}


module "nat" {
  source                     = "../../modules/nat_v2"
  ami_id                     = data.terraform_remote_state.paperwork.outputs.amzn_ami_id
  private_route_table_ids    = data.aws_route_tables.es_private_route_tables.ids
  ingress_cidr_blocks        = [data.aws_vpc.this_vpc.cidr_block]
  metrics_ingress_cidr_block = data.aws_vpc.pas_vpc.cidr_block
  tags                       = { tags = local.modified_tags, instance_tags = var.global_vars["instance_tags"] }
  public_subnet_ids          = data.terraform_remote_state.es.outputs.public_subnet_ids
  ssh_cidr_blocks            = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_cidrs
  internetless               = var.internetless
  instance_types             = data.terraform_remote_state.scaling-params.outputs.instance_types
  scale_vpc_key              = "enterprise-services"
  user_data                  = data.template_cloudinit_config.nat_user_data.rendered
  root_domain                = data.terraform_remote_state.paperwork.outputs.root_domain
  syslog_ca_cert             = data.terraform_remote_state.paperwork.outputs.syslog_ca_certs_bundle
  bot_key_pem                = data.terraform_remote_state.paperwork.outputs.bot_private_key
  check_cloud_init           = data.terraform_remote_state.paperwork.outputs.check_cloud_init == "false" ? false : true
  operating_system           = data.terraform_remote_state.paperwork.outputs.amazon_operating_system_tag

  public_bucket_name = data.terraform_remote_state.paperwork.outputs.public_bucket_name
  public_bucket_url  = data.terraform_remote_state.paperwork.outputs.public_bucket_url
  role_name          = data.terraform_remote_state.paperwork.outputs.instance_tagger_role_name
}

variable "internetless" {
}

variable "remote_state_region" {
}

variable "remote_state_bucket" {
}

variable "global_vars" {
  type = any
}

output "ssh_host_ips" {
  value = module.nat.ssh_host_ips
}

module "sshconfig" {
  source              = "../../modules/ssh_config"
  foundation_name     = data.terraform_remote_state.paperwork.outputs.foundation_name
  host_ips            = module.nat.ssh_host_ips
  host_type           = "enterprise_services_nat"
  secrets_bucket_name = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
}