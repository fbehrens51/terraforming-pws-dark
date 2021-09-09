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

variable "global_vars" {
  type = any
}

variable "internetless" {
}

variable "loki_bundle_key" {
  description = "Loki bundle S3 object key, aka filename."
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

data "terraform_remote_state" "scaling-params" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "scaling-params"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_loki" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_loki"
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
  modified_name = "${local.env_name} loki"
  modified_tags = merge(
    var.global_vars["global_tags"],
    var.global_vars["instance_tags"],
    {
      "Name"       = local.modified_name
      "MetricsKey" = data.terraform_remote_state.paperwork.outputs.metrics_key,
      "job"        = "loki",
    },
  )

  encrypted_amazon2_ami_id = data.terraform_remote_state.paperwork.outputs.amzn_ami_id
}

data "aws_vpc" "es_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.es_vpc_id
}

data "aws_vpc" "pas_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
}

module "configuration" {
  source = "./modules/config"

  public_bucket_name = data.terraform_remote_state.paperwork.outputs.public_bucket_name
  public_bucket_url  = data.terraform_remote_state.paperwork.outputs.public_bucket_url

  loki_bundle_key = var.loki_bundle_key
  loki_ips        = data.terraform_remote_state.bootstrap_loki.outputs.loki_eni_ips
  storage_bucket  = data.terraform_remote_state.bootstrap_loki.outputs.storage_bucket
  root_domain     = data.terraform_remote_state.paperwork.outputs.root_domain

  region = var.region
}

data "template_cloudinit_config" "user_data" {
  count         = length(data.terraform_remote_state.bootstrap_loki.outputs.loki_eni_ips)
  base64_encode = true
  gzip          = true

  part {
    filename     = "config.cfg"
    content_type = "text/x-include-url"
    content      = module.configuration.config_user_data[count.index]
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
    filename     = "syslog.cfg"
    content      = module.syslog_config.user_data
    content_type = "text/x-include-url"
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

module "syslog_ports" {
  source = "../../modules/syslog_ports"
}

module "iptables_rules" {
  source = "../../modules/iptables"
  personality_rules = [
    "iptables -A INPUT -p tcp --dport ${module.syslog_ports.loki_http_port} -m state --state NEW -j ACCEPT",
    "iptables -A INPUT -p tcp --dport ${module.syslog_ports.loki_grpc_port} -m state --state NEW -j ACCEPT",
    "iptables -A INPUT -p tcp --dport ${module.syslog_ports.loki_bind_port} -m state --state NEW -j ACCEPT",
  ]
  control_plane_subnet_cidrs = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_cidrs
}

module "loki_instance" {
  count             = length(data.terraform_remote_state.bootstrap_loki.outputs.loki_eni_ids)
  source            = "../../modules/launch"
  instance_types    = data.terraform_remote_state.scaling-params.outputs.instance_types
  scale_vpc_key     = "enterprise-services"
  scale_service_key = "loki"
  ami_id            = local.encrypted_amazon2_ami_id
  user_data         = data.template_cloudinit_config.user_data[count.index].rendered
  eni_ids           = data.terraform_remote_state.bootstrap_loki.outputs.loki_eni_ids
  tags              = local.modified_tags
  check_cloud_init  = false
  bot_key_pem       = data.terraform_remote_state.paperwork.outputs.bot_private_key
  # TODO: replace with loki role, since loki role will need delete access to this one bucket
  iam_instance_profile = data.terraform_remote_state.paperwork.outputs.fluentd_role_name
}

resource "aws_lb_target_group_attachment" "loki_http_attachment" {
  count            = length(data.terraform_remote_state.bootstrap_loki.outputs.loki_eni_ids)
  target_group_arn = data.terraform_remote_state.bootstrap_loki.outputs.loki_http_target_group
  target_id        = module.loki_instance[count.index].instance_ids[0]
}

resource "aws_lb_target_group_attachment" "loki_apps_grpc_attachment" {
  count            = length(data.terraform_remote_state.bootstrap_loki.outputs.loki_eni_ids)
  target_group_arn = data.terraform_remote_state.bootstrap_loki.outputs.loki_grpc_target_group
  target_id        = module.loki_instance[count.index].instance_ids[0]
}

module "syslog_config" {
  source         = "../../modules/syslog"
  root_domain    = data.terraform_remote_state.paperwork.outputs.root_domain
  syslog_ca_cert = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs

  role_name          = "loki"
  public_bucket_name = data.terraform_remote_state.paperwork.outputs.public_bucket_name
  public_bucket_url  = data.terraform_remote_state.paperwork.outputs.public_bucket_url
}

resource "null_resource" "loki_status" {
  count = length(data.terraform_remote_state.bootstrap_loki.outputs.loki_eni_ids)
  triggers = {
    instance_id = module.loki_instance[count.index].instance_ids[0]
  }

  provisioner "local-exec" {
    on_failure  = fail
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOF
    #!/usr/bin/env bash
    set -e
    completed_tag="cloud_init_done"
    poll_tags="aws ec2 describe-tags --filters Name=resource-id,Values=${module.loki_instance[count.index].instance_ids[0]} Name=key,Values=$completed_tag --output text --query Tags[*].Value"
    echo "running $poll_tags"
    tags="$($poll_tags)"
    COUNTER=0
    LOOP_LIMIT=30
    while [[ "$tags" == "" ]] ; do
      if [[ $COUNTER -eq $LOOP_LIMIT ]]; then
        echo "timed out waiting for $completed_tag to be set"
        exit 1
      fi
      if [[ $COUNTER -gt 0 ]]; then
        echo "$completed_tag not set, sleeping for 10s"
        sleep 10s
      fi
      tags="$($poll_tags)"
      let COUNTER=COUNTER+1
    done
    echo "$completed_tag = $tags"
    EOF
  }
}

output "loki_ip" {
  value = flatten(module.loki_instance.*.private_ips)
}
