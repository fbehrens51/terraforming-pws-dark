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
  modified_name    = "${local.env_name} rapid7-engine"
  modified_tags = merge(
  var.global_vars["global_tags"],
  var.global_vars["instance_tags"],
  {
    "Name"            = local.modified_name
    "MetricsKey"      = data.terraform_remote_state.paperwork.outputs.metrics_key
    "foundation_name" = data.terraform_remote_state.paperwork.outputs.foundation_name
    "job"             = "rapid7-enging"
  }
  )
}




data "aws_vpc" "cp_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.cp_vpc_id
}


#locals {
#  instance_type = data.terraform_remote_state.scaling-params.outputs.instance_types["control-plane"]["r7-engine"]
#}
##The Scan Engine available on the AWS Marketplace is designed to only scan assets that have been detected by Dynamic Discovery
##This is done to ensure you are in compliance with AWS policies on penetration testing and not unintentionally scanning assets you do not own.
#resource "aws_cloudformation_stack" "rapid7_engine" {
#  name = "rapid7-engine"
#  //The following is required since the stack creates a custom IAM Role/Instance Profile
#  capabilities = ["CAPABILITY_NAMED_IAM"]
#
#  parameters = {
#    SecurityConsoleHost = var.SecurityConsoleHost
##    SecurityConsolePort = ""
#    SecurityConsoleSecret = var.SecurityConsoleSecret
#    InstanceType = local.instance_type
##    RootVolumeSize = default is 100
#    VPC = data.aws_vpc.cp_vpc.id
#    Subnet = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_ids[2]
#    AssociateEngineWithPublicIpAddress = "False"
#    CreateNewSecurityGroupsParam = "No"
#    ExistingScanEngineSecurityGroupID = "sg-0c9a462d2961c4ae8"
#    AddIngressToConsoleSecurityGroup = "No"
##    ConsoleSecurityGroupIDToUpdate=var.ConsoleSecurityGroupIDToUpdate
#  }
#
#//URL from AMI (Rapid7 Engine) description or AWS Marketplace
#template_url = "https://s3.amazonaws.com/awsmp-fulfillment-cf-templates-prod/6c1d73f4-a148-4214-92ba-95221bb0951c.be334229-6d83-4df1-8213-2d7aa12cfb52.template"
#}



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

  role_name          = "rapid7-engine"
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

module "rapid7-engine" {
  instance_count       = 2
  source               = "../../modules/launch"
  ami_id               = data.terraform_remote_state.paperwork.outputs.amzn_ami_id
  user_data            = data.template_cloudinit_config.user_data.rendered
  eni_ids              = data.terraform_remote_state.bootstrap_rapid7.outputs.scanner_eni_ids
  iam_instance_profile = data.terraform_remote_state.paperwork.outputs.instance_tagger_role_name
  instance_types       = data.terraform_remote_state.scaling-params.outputs.instance_types
  scale_vpc_key        = "control-plane"
  scale_service_key    = "r7-engine"
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

//TODO:script???
//https://docs.rapid7.com/insightvm/configuring-distributed-scan-engines
//wget https://download2.rapid7.com/download/InsightVM/Rapid7Setup-Linux64.bin
//wget https://download2.rapid7.com/download/InsightVM/Rapid7Setup-Linux64.bin.sha512sum
//sha512sum -c Rapid7Setup-Linux64.bin.sha512sum
//chmod +x Rapid7Setup-Linux64.bin
//./Rapid7Setup-Linux64.bin -c