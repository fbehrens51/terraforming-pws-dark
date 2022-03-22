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


data "terraform_remote_state" "bootstrap_rapid7" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_rapid7"
    region  = var.remote_state_region
    encrypt = true
  }
}

locals {
  env_name         = var.global_vars.env_name
  modified_name    = "${local.env_name} rapid7"
  modified_tags = merge(
  var.global_vars["global_tags"],
  var.global_vars["instance_tags"],
  {
    "Name"            = local.modified_name
    "MetricsKey"      = data.terraform_remote_state.paperwork.outputs.metrics_key
    "foundation_name" = data.terraform_remote_state.paperwork.outputs.foundation_name
    "job"             = "rapid7"
  }
  )
}


data "template_file" "root_directory" {
  template = <<EOF
bootcmd:
  - |
    set -ex
    growpart /dev/nvme0n1 2
    pvresize /dev/nvme0n1p2
    lvextend -r -l +100%FREE /dev/vg0/root
EOF
}

module "syslog_config" {
  source = "../../modules/syslog"

  root_domain    = data.terraform_remote_state.paperwork.outputs.root_domain
  syslog_ca_cert = data.terraform_remote_state.paperwork.outputs.syslog_ca_certs_bundle

  role_name          = "rapid7"
  public_bucket_name = data.terraform_remote_state.paperwork.outputs.public_bucket_name
  public_bucket_url  = data.terraform_remote_state.paperwork.outputs.public_bucket_url
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
    filename     = "config.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.root_directory.rendered
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "syslog.cfg"
    content      = module.syslog_config.user_data
    content_type = "text/x-include-url"
  }

  part {
    filename     = "user_accounts_user_data.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.bot_user_accounts_user_data
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

module "rapid7" {
  instance_count       = 1
  source               = "../../modules/launch"
  ami_id               = data.terraform_remote_state.paperwork.outputs.amzn_ami_id
  user_data            = data.template_cloudinit_config.user_data.rendered
  eni_ids              = data.terraform_remote_state.bootstrap_rapid7.outputs.eni_ids
  iam_instance_profile = data.terraform_remote_state.paperwork.outputs.instance_tagger_role_name
  instance_types       = data.terraform_remote_state.scaling-params.outputs.instance_types
  scale_vpc_key        = "control-plane"
  scale_service_key    = "r7-scanner"
  operating_system     = data.terraform_remote_state.paperwork.outputs.amazon_operating_system_tag

  tags = local.modified_tags

  root_block_device = {
    volume_type = "gp2"
    volume_size = 200
  }

  bot_key_pem = data.terraform_remote_state.paperwork.outputs.bot_private_key

  check_cloud_init   = data.terraform_remote_state.paperwork.outputs.check_cloud_init == "false" ? false : true
  cloud_init_timeout = 450
}

module "domains" {
  source = "../../modules/domains"

  root_domain = data.terraform_remote_state.paperwork.outputs.root_domain
}
