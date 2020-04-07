provider "aws" {
}

module "providers" {
  source = "../../modules/dark_providers"
}

terraform {
  backend "s3" {
  }
}

locals {
  env_name      = var.tags["Name"]
  modified_name = "${local.env_name} sjb"
  modified_tags = merge(
    var.tags,
    {
      "Name" = local.modified_name
    },
  )

  root_domain = data.terraform_remote_state.paperwork.outputs.root_domain
  tld         = regex("[^\\.]+$", local.root_domain) # will match com in ci, dev, and staging environments.
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

data "terraform_remote_state" "bastion" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bastion"
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

data "terraform_remote_state" "encrypt_amis" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "encrypt_amis"
    region  = var.remote_state_region
    encrypt = true
  }
}

locals {
  transfer_bucket_name  = data.terraform_remote_state.bootstrap_control_plane.outputs.transfer_bucket_name
  terraform_bucket_name = data.terraform_remote_state.bootstrap_control_plane.outputs.terraform_bucket_name
  terraform_region      = data.terraform_remote_state.bootstrap_control_plane.outputs.terraform_region
}

data "template_file" "setup_source_zip" {
  template = <<EOF
runcmd:
  - |
    echo "Downloading and extracting source.zip"
    mkdir /home/ec2-user/workspace
    cd /home/ec2-user/workspace
    latest=$(aws --region ${var.region} s3 ls s3://${local.transfer_bucket_name}/pcf-eagle-automation/ | awk '/ pcf-eagle-automation.*\.zip$/ {print $4}' | sort -n | tail -1)
    aws --region ${var.region} s3 cp --no-progress s3://${local.transfer_bucket_name}/pcf-eagle-automation/$latest .
    mkdir -p pcf-eagle-automation
    unzip -d ./pcf-eagle-automation $latest
    rm $latest
    latest=$(aws --region ${var.region} s3 ls s3://${local.transfer_bucket_name}/terraforming-pws-dark/ | awk '/ terraforming-pws-dark.*\.zip$/ {print $4}' | sort -n | tail -1)
    aws --region ${var.region} s3 cp --no-progress s3://${local.transfer_bucket_name}/terraforming-pws-dark/$latest .
    mkdir -p terraforming-pws-dark
    unzip -d ./terraforming-pws-dark $latest
    rm $latest
EOF

}

data "template_file" "setup_system_tools" {
  template = <<EOF
runcmd:
  - echo "Installing up system tools and utilities"
  - yum install jq git python-pip python3 -y
  - pip3 install yq --index-url=$${pypi_host_protocol}://$${pypi_host}/simple --trusted-host=$${pypi_host}
EOF


  vars = {
    pypi_host          = var.pypi_host
    pypi_host_protocol = var.pypi_host_secure ? "https" : "http"
  }
}

data "template_file" "setup_tools_zip" {
  template = <<EOF
runcmd:
  - |
    echo "Downloading and extracting tools.zip"
    latest=$(aws --region ${var.region} s3 ls s3://${local.transfer_bucket_name}/cli-tools/ | awk '/ tools.*\.zip$/ {print $4}' | sort -n | tail -1)
    aws --region ${var.region} s3 cp s3://${local.transfer_bucket_name}/cli-tools/$latest .
    unzip $latest
    rm $latest
    install tools/* /usr/local/bin/
    rm -rf tools
EOF

}

data "template_file" "setup_terraform_zip" {
  template = <<EOF
runcmd:
  - |
    echo "Downloading and extracting terraform.zip"
    mkdir terraform
    latest=$(aws --region ${local.terraform_region} s3 ls s3://${local.terraform_bucket_name}/terraform-bundle/ | awk '/ terraform-bundle.*\.zip$/ {print $4}' | sort -n | tail -1)
    aws --region ${local.terraform_region} s3 cp s3://${local.terraform_bucket_name}/terraform-bundle/$latest .
    unzip -d terraform $latest
    rm $latest
    mkdir -p /home/ec2-user/.terraform.d/plugins/linux_amd64/ /root/.terraform.d/plugins/linux_amd64/
    install -o ec2-user -g ec2-user terraform/terraform-provider* /home/ec2-user/.terraform.d/plugins/linux_amd64/.
    install terraform/terraform-provider* /root/.terraform.d/plugins/linux_amd64/.
    install terraform/terraform /usr/local/bin/
    rm -rf terraform
EOF

}

data "template_file" "chown_home_directory" {
  template = <<EOF
runcmd:
  - echo "Chowning ~/ec2-user"
  - chown -R ec2-user:ec2-user ~ec2-user/
EOF

}

module "syslog_config" {
  source = "../../modules/syslog"

  root_domain           = local.root_domain
  splunk_syslog_ca_cert = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs

  role_name          = "sjb"
  public_bucket_name = data.terraform_remote_state.paperwork.outputs.public_bucket_name
  public_bucket_url  = data.terraform_remote_state.paperwork.outputs.public_bucket_url
}

data "template_cloudinit_config" "user_data" {
  base64_encode = true
  gzip          = true

  part {
    filename     = "syslog.cfg"
    content      = module.syslog_config.user_data
    content_type = "text/x-include-url"
  }

  # source.zip
  part {
    filename     = "source_code_zip.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.setup_source_zip.rendered
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "terraform_zip.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.setup_terraform_zip.rendered
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "tools_zip.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.setup_tools_zip.rendered
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "system_tools.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.setup_system_tools.rendered
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "chown_home_dir.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.chown_home_directory.rendered
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
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
    filename     = "banner.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.custom_banner_user_data
  }
}

module "sjb" {
  instance_count       = 1
  source               = "../../modules/launch"
  ami_id               = data.terraform_remote_state.encrypt_amis.outputs.encrypted_amazon2_ami_id
  user_data            = data.template_cloudinit_config.user_data.rendered
  eni_ids              = data.terraform_remote_state.bootstrap_control_plane.outputs.sjb_eni_ids
  iam_instance_profile = data.terraform_remote_state.paperwork.outputs.sjb_role_name
  instance_type        = var.instance_type

  tags = merge(
    local.modified_tags,
    {
      "Name" = "${local.env_name}-sjb"
    },
  )

  root_block_device = {
    volume_type = "gp2"
    volume_size = 64
  }

  bot_key_pem  = data.terraform_remote_state.paperwork.outputs.bot_private_key
  bastion_host = local.tld == "com" ? data.terraform_remote_state.bastion.outputs.bastion_ip : null
}
