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

  env_name        = var.global_vars.env_name
  modified_name   = "${local.env_name} scanner-commercial ${random_string.random.result}"
  env_name_suffix = upper(element(split(" ", local.env_name), length(split(" ", local.env_name)) - 1))

  modified_tags = merge(
    var.global_vars["global_tags"],
    var.global_vars["instance_tags"],
    {
      "Name"            = local.modified_name
      "foundation_name" = data.terraform_remote_state.paperwork.outputs.foundation_name
      "job"             = "scanner-commercial"
    },
  )
}


data "aws_ami" "scanner_ami" {
  most_recent = true
  owners      = ["aws-marketplace"]
  name_regex  = "Nessus*"
  filter {
    name   = "product-code"
    values = ["4m4uvwtrl5t872c56wb131ttw"]
  }

}

data "aws_region" "current" {
}

resource "random_string" "random" {
  length  = 16
  special = false
  keepers = {
    ami_id               = data.aws_ami.scanner_ami.image_id
    eni_ids              = data.terraform_remote_state.bootstrap_scanner.outputs.scanner_eni_ids[0]
    iam_instance_profile = data.terraform_remote_state.bootstrap_scanner.outputs.commercial_scanner_instance_profile_name
    //    instance_types       = data.terraform_remote_state.scaling-params.outputs.instance_types
    bot_key_pem = data.terraform_remote_state.paperwork.outputs.bot_private_key
  }
}

module "scanner" {
  instance_count = var.disable_scanner ? 0 : 1
  source         = "../../modules/launch"
  ami_id         = data.aws_ami.scanner_ami.image_id
  //AWS_<region>_<JIRA Project Prefix>_<ENV>
  user_data            = <<EOF
{
"name": "AWS_${data.aws_region.current.name}_TWSG_${local.env_name_suffix}_${random_string.random.result}",
"key": "fde31e16c21c886d6de8d88b796b2fb1d9823f29ecf7338b41a8f43ac12d707c",
"iam_role": "${data.terraform_remote_state.bootstrap_scanner.outputs.commercial_scanner_instance_profile_name}"
}
EOF
  eni_ids              = data.terraform_remote_state.bootstrap_scanner.outputs.scanner_eni_ids
  iam_instance_profile = data.terraform_remote_state.bootstrap_scanner.outputs.commercial_scanner_instance_profile_name
  instance_types       = data.terraform_remote_state.scaling-params.outputs.instance_types
  scale_vpc_key        = "control-plane"
  scale_service_key    = "scanner"
  operating_system     = data.terraform_remote_state.paperwork.outputs.amazon_operating_system_tag

  tags = local.modified_tags

  root_block_device = {
    volume_type = "gp2"
    volume_size = 38
  }

  bot_key_pem = data.terraform_remote_state.paperwork.outputs.bot_private_key

  check_cloud_init = false
}

output "ssh_host_ips" {
  value = zipmap(flatten(module.scanner.ssh_host_names), flatten(module.scanner.private_ips))
}
