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

locals {

  terraform_bucket_name = data.terraform_remote_state.bootstrap_control_plane.outputs.terraform_bucket_name
  terraform_region      = data.terraform_remote_state.bootstrap_control_plane.outputs.terraform_region

  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} scanner"
  modified_tags = merge(
    var.global_vars["global_tags"],
    var.global_vars["instance_tags"],
    {
      "Name"       = local.modified_name
      "MetricsKey" = data.terraform_remote_state.paperwork.outputs.metrics_key,
      "job"        = "scanner"
    },
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
    wget --no-check-certificate "$${package_url}"
    yum install *.rpm -y
    systemctl start nessusd
    sleep 30
    curl 'https://localhost:8834/users' \
    -H 'Content-Type: application/json' \
    -H 'Accept: */*' \
    --data-raw $'{"username":"$${username}","password":"$${password}","permissions":128}' \
    --compressed \
    --insecure
    sleep 5
    #restart
    curl 'https://localhost:8834/server/restart' \
    -X 'POST' \
    -H 'Content-Type: application/json' \
    -H 'Accept: */*' \
    --compressed \
    --insecure
    echo 1 > /proc/sys/net/ipv4/ip_forward
    echo -e "\nnet.ipv4.ip_forward = 1" >>/etc/sysctl.conf
    iptables -t nat -A PREROUTING --source 0/0 --destination 0/0 -p tcp --dport 443 -j REDIRECT --to-ports 8834
    iptables-save > /etc/sysconfig/iptables
EOF

  vars = {
    username    = var.scanner_username
    password    = var.scanner_password
    package_url = var.scanner_package_url
  }
}

//if we can use the rpm instead of the AMI...
//data "template_file" "setup_io_scanner" {
//  template = <<EOF
//runcmd:
//  - |
//    wget --no-check-certificate "$${package_url}"
//    yum install *.rpm -y
//    systemctl start nessusd
//    sleep 30
//    echo 1 > /proc/sys/net/ipv4/ip_forward
//    echo -e "\nnet.ipv4.ip_forward = 1" >>/etc/sysctl.conf
//    iptables -t nat -A PREROUTING --source 0/0 --destination 0/0 -p tcp --dport 443 -j REDIRECT --to-ports 8834
//    iptables-save > /etc/sysconfig/iptables
//EOF
//
//  vars = {
//    package_url = var.scanner_package_url
//  }
//}

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

  # This must be last - updates the AIDE DB after all installations/configurations are complete.
  part {
    filename     = "hardening.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.server_hardening_user_data
  }
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

  check_cloud_init = data.terraform_remote_state.paperwork.outputs.check_cloud_init == "false" ? false : true
}

output "scanner_private_ip" {
  value = module.scanner.private_ips[0]
}
