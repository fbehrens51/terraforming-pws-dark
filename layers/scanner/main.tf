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

data "terraform_remote_state" "pas" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "pas"
    region  = var.remote_state_region
    encrypt = true
  }
}


data "terraform_remote_state" "bootstrap_scanner" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_scanner"
    region  = var.remote_state_region
    encrypt = true
  }
}

resource "random_string" "random" {
  length  = 16
  special = false
  keepers = {
    eni_ids     = data.terraform_remote_state.bootstrap_scanner.outputs.scanner_eni_ids[0]
    bot_key_pem = data.terraform_remote_state.paperwork.outputs.bot_private_key
  }
}

resource "random_password" "password" {
  length           = 12
  special          = true
  override_special = "_%@!"
}

locals {
  scanner_username = "tas_scanner"
  env_name         = var.global_vars.env_name
  modified_name    = "${local.env_name} scanner"
  env_arr          = split(" ", local.env_name)
  env_short_name   = upper(element(local.env_arr, length(local.env_arr) - 1))
  scanner_name     = "TWSG-${local.env_short_name}-SCANNER-${random_string.random.result}"
  scanner_group    = "TWSG-${local.env_short_name}-SCANNERS"
  scanner_password = random_password.password.result
  modified_tags = merge(
    var.global_vars["global_tags"],
    var.global_vars["instance_tags"],
    {
      "Name"       = local.modified_name
      "MetricsKey" = data.terraform_remote_state.paperwork.outputs.metrics_key,
      "job"        = "scanner"
    }
  )
}


module "syslog_config" {
  source = "../../modules/syslog"

  root_domain    = data.terraform_remote_state.paperwork.outputs.root_domain
  syslog_ca_cert = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs

  role_name          = "scanner"
  public_bucket_name = data.terraform_remote_state.paperwork.outputs.public_bucket_name
  public_bucket_url  = data.terraform_remote_state.paperwork.outputs.public_bucket_url
}

data "template_file" "setup_scanner" {
  template = <<EOF
runcmd:
  - |
    growpart /dev/nvme0n1 2
    pvresize /dev/xvda2
    lvextend -r -L +32G /dev/mapper/vg0-root
    lvextend -r -L +10G /dev/mapper/vg0-tmp
    lvextend -r -L +8G /dev/mapper/vg0-log
    lvextend -r -L +2G /dev/mapper/vg0-audit
    lvextend -r -l +100%FREE  /dev/mapper/vg0-vartmp
    echo 1 > /proc/sys/net/ipv4/ip_forward
    echo -e "\nnet.ipv4.ip_forward = 1" >>/etc/sysctl.conf
    iptables -t nat -A PREROUTING --source 0/0 --destination 0/0 -p tcp --dport 443 -j REDIRECT --to-ports 8834
    iptables-save > /etc/sysconfig/iptables
    curl -H 'X-Key: fde31e16c21c886d6de8d88b796b2fb1d9823f29ecf7338b41a8f43ac12d707c' 'https://cloud.tenable.com/install/scanner?name=$${scanner_name}&groups=$${scanner_group}' | bash -x
    sleep 10
    systemctl start nessusd
    sleep 60
    /opt/nessus/sbin/nessuscli adduser $${username} << ENDDOC
    $${password}
    $${password}
    y

    y
    ENDDOC


    EOF

  vars = {
    username      = local.scanner_username
    password      = local.scanner_password
    scanner_name  = local.scanner_name
    scanner_group = local.scanner_group
  }
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

  # scanner configuration
  part {
    filename     = "scanner.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.setup_scanner.rendered
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "postfix_client.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.postfix_client_user_data
  }

// Takes 35 minutes to run last AIDE update....ticket to refactor
//  # This must be last - updates the AIDE DB after all installations/configurations are complete.
//  part {
//    filename     = "hardening.cfg"
//    content_type = "text/x-include-url"
//    content      = data.terraform_remote_state.paperwork.outputs.server_hardening_user_data
//  }
}

module "scanner" {
  instance_count       = 1
  source               = "../../modules/launch"
  ami_id               = data.terraform_remote_state.paperwork.outputs.amzn_ami_id
  user_data            = data.template_cloudinit_config.user_data.rendered
  eni_ids              = data.terraform_remote_state.bootstrap_scanner.outputs.scanner_eni_ids
  iam_instance_profile = data.terraform_remote_state.paperwork.outputs.instance_tagger_role_name
  instance_types       = data.terraform_remote_state.scaling-params.outputs.instance_types
  scale_vpc_key        = "control-plane"
  scale_service_key    = "scanner"

  tags = local.modified_tags

  root_block_device = {
    volume_type = "gp2"
    volume_size = 64
  }

  bot_key_pem = data.terraform_remote_state.paperwork.outputs.bot_private_key

  check_cloud_init   = data.terraform_remote_state.paperwork.outputs.check_cloud_init == "false" ? false : true
  cloud_init_timeout = 450
}

output "scanner_username" {
  value = local.scanner_username
}

output "scanner_password" {
  value = local.scanner_password
  sensitive = true
}

output "scanner_name" {
  value = local.scanner_name
}