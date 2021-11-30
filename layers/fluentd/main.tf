variable "remote_state_region" {
}

variable "remote_state_bucket" {
}

variable "global_vars" {
  type = any
}

variable "internetless" {
}

variable "fluentd_bundle_key" {
  description = "Fluentd bundle S3 object key, aka filename."
}

variable "region" {
}

variable "enable_loki" {
  type    = bool
  default = false
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
  modified_name = "${local.env_name} fluentd"
  modified_tags = merge(
    var.global_vars["global_tags"],
    var.global_vars["instance_tags"],
    {
      "Name"            = local.modified_name
      "MetricsKey"      = data.terraform_remote_state.paperwork.outputs.metrics_key,
      "foundation_name" = data.terraform_remote_state.paperwork.outputs.foundation_name
      "job"             = "fluentd",
    },
  )

  audit_log_group_name = data.terraform_remote_state.bootstrap_fluentd.outputs.audit_log_group_name
  log_group_name       = data.terraform_remote_state.bootstrap_fluentd.outputs.log_group_name
  log_stream_name      = "\"fluentd_syslog_#{ENV['AWSAZ']}\""

  encrypted_amazon2_ami_id = data.terraform_remote_state.paperwork.outputs.amzn_ami_id

  loki_config = var.enable_loki ? {
    enabled          = true
    loki_url         = data.terraform_remote_state.bootstrap_loki[0].outputs.loki_url
    loki_password    = data.terraform_remote_state.bootstrap_loki[0].outputs.loki_password
    loki_username    = data.terraform_remote_state.bootstrap_loki[0].outputs.loki_username
    loki_client_cert = data.terraform_remote_state.paperwork.outputs.loki_client_cert
    loki_client_key  = data.terraform_remote_state.paperwork.outputs.loki_client_key
    } : {
    enabled          = false
    loki_url         = ""
    loki_password    = ""
    loki_username    = ""
    loki_client_cert = ""
    loki_client_key  = ""
  }
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

  ca_cert     = data.terraform_remote_state.paperwork.outputs.root_ca_cert
  server_cert = data.terraform_remote_state.paperwork.outputs.fluentd_server_cert
  server_key  = data.terraform_remote_state.paperwork.outputs.fluentd_server_key

  fluentd_bundle_key = var.fluentd_bundle_key

  cloudwatch_audit_log_group_name = local.audit_log_group_name
  cloudwatch_log_group_name       = local.log_group_name
  cloudwatch_log_stream_name      = local.log_stream_name
  s3_logs_bucket                  = data.terraform_remote_state.bootstrap_fluentd.outputs.s3_bucket_syslog_archive
  s3_audit_logs_bucket            = data.terraform_remote_state.bootstrap_fluentd.outputs.s3_bucket_syslog_audit_archive
  region                          = var.region
  s3_path                         = "logs/"

  loki_config = local.loki_config
}

module "domains" {
  source      = "../../modules/domains"
  root_domain = data.terraform_remote_state.paperwork.outputs.root_domain
}

data "template_cloudinit_config" "user_data" {
  base64_encode = true
  gzip          = true

  // tag_completion has to be first, it sets a bash trap to ensure the tagger runs when an error occurs
  part {
    filename     = "tag_completion.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.completion_tag_user_data
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

  // syslog has to come after clamav because it uses augtool, which is installed by clamav
  // this only applies to this layer, since fluentd is the only one to setup local syslog forwarding
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
  personality_rules = [
    "iptables -A INPUT -p tcp --dport 8090                -m state --state NEW -j ACCEPT",
    "iptables -A INPUT -p tcp --dport 8091                -m state --state NEW -j ACCEPT",
    "iptables -A INPUT -p tcp --dport 8888                -m state --state NEW -j ACCEPT",
    "iptables -A INPUT -p tcp --dport 9200                -m state --state NEW -j ACCEPT"
  ]
  control_plane_subnet_cidrs = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_cidrs
}

module "fluentd_instance" {
  instance_count       = length(data.terraform_remote_state.bootstrap_fluentd.outputs.fluentd_eni_ids)
  source               = "../../modules/launch"
  instance_types       = data.terraform_remote_state.scaling-params.outputs.instance_types
  scale_vpc_key        = "enterprise-services"
  scale_service_key    = "fluentd"
  ami_id               = local.encrypted_amazon2_ami_id
  user_data            = data.template_cloudinit_config.user_data.rendered
  eni_ids              = data.terraform_remote_state.bootstrap_fluentd.outputs.fluentd_eni_ids
  tags                 = local.modified_tags
  check_cloud_init     = false
  bot_key_pem          = data.terraform_remote_state.paperwork.outputs.bot_private_key
  iam_instance_profile = data.terraform_remote_state.paperwork.outputs.fluentd_role_name
  volume_ids           = data.terraform_remote_state.bootstrap_fluentd.outputs.volume_id
  operating_system     = data.terraform_remote_state.paperwork.outputs.amazon_operating_system_tag
}

resource "aws_lb_target_group_attachment" "fluentd_syslog_attachment" {
  count            = length(data.terraform_remote_state.bootstrap_fluentd.outputs.fluentd_eni_ids)
  target_group_arn = data.terraform_remote_state.bootstrap_fluentd.outputs.fluentd_lb_syslog_tg_arn
  target_id        = module.fluentd_instance.instance_ids[count.index]
}

resource "aws_lb_target_group_attachment" "fluentd_apps_syslog_attachment" {
  count            = length(data.terraform_remote_state.bootstrap_fluentd.outputs.fluentd_eni_ids)
  target_group_arn = data.terraform_remote_state.bootstrap_fluentd.outputs.fluentd_lb_apps_syslog_tg_arn
  target_id        = module.fluentd_instance.instance_ids[count.index]
}

module "syslog_config" {
  source         = "../../modules/syslog"
  root_domain    = data.terraform_remote_state.paperwork.outputs.root_domain
  syslog_ca_cert = data.terraform_remote_state.paperwork.outputs.root_ca_cert

  role_name          = "fluentd"
  forward_locally    = true
  public_bucket_name = data.terraform_remote_state.paperwork.outputs.public_bucket_name
  public_bucket_url  = data.terraform_remote_state.paperwork.outputs.public_bucket_url
}

resource "null_resource" "fluentd_status" {
  count = length(data.terraform_remote_state.bootstrap_fluentd.outputs.fluentd_eni_ids)
  triggers = {
    instance_id = module.fluentd_instance.instance_ids[count.index]
  }

  provisioner "local-exec" {
    on_failure  = fail
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOF
    #!/usr/bin/env bash
    set -e
    completed_tag="cloud_init_done"
    poll_tags="aws ec2 describe-tags --filters Name=resource-id,Values=${module.fluentd_instance.instance_ids[count.index]} Name=key,Values=$completed_tag --output text --query Tags[*].Value"
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

    if cloud_init_message="$( aws ec2 describe-tags --filters Name=resource-id,Values=${module.fluentd_instance.instance_ids[count.index]} Name=key,Values=cloud_init_output --output text --query Tags[*].Value )"; then
      [[ ! -z $cloud_init_message ]] && echo -e "cloud_init_output: $( echo -ne "$cloud_init_message" | openssl enc -d -a | gunzip -qc - )"
    fi

    [[ $tags == false ]] && exit 1 || exit 0
    EOF
  }
}

output "fluent_ip" {
  value = module.fluentd_instance.private_ips
}

output "ssh_host_ips" {
  value = zipmap(flatten(module.fluentd_instance.ssh_host_names), flatten(module.fluentd_instance.private_ips))
}
