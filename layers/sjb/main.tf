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
  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} sjb"
  modified_tags = merge(
    var.global_vars["global_tags"],
    var.global_vars["instance_tags"],
    {
      "Name"       = local.modified_name
      "MetricsKey" = data.terraform_remote_state.paperwork.outputs.metrics_key,
      "job"        = "sjb"
    },
  )

  root_domain = data.terraform_remote_state.paperwork.outputs.root_domain
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
    aws --region ${var.region} s3 cp --no-progress s3://${local.transfer_bucket_name}/pcf-eagle-automation/$latest . --no-progress
    mkdir -p pcf-eagle-automation
    unzip -q -d ./pcf-eagle-automation $latest
    rm $latest
    latest=$(aws --region ${var.region} s3 ls s3://${local.transfer_bucket_name}/terraforming-pws-dark/ | awk '/ terraforming-pws-dark.*\.zip$/ {print $4}' | sort -n | tail -1)
    aws --region ${var.region} s3 cp --no-progress s3://${local.transfer_bucket_name}/terraforming-pws-dark/$latest . --no-progress
    mkdir -p terraforming-pws-dark
    unzip -q -d ./terraforming-pws-dark $latest
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
    aws --region ${var.region} s3 cp s3://${local.transfer_bucket_name}/cli-tools/$latest . --no-progress
    unzip -q $latest
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
    aws --region ${local.terraform_region} s3 cp s3://${local.terraform_bucket_name}/terraform-bundle/$latest . --no-progress
    unzip -q -d terraform $latest
    rm $latest
    mkdir -p /home/ec2-user/.terraform.d /root/.terraform.d
    cp -pr terraform/plugins ~ec2-user/.terraform.d/
    chown -R ec2-user:ec2-user ~ec2-user/.terraform.d
    cp -pr terraform/plugins /root/.terraform.d/
    install terraform/terraform /usr/local/bin/
    rm -rf terraform

write_files:
  - content: |
      disable_checkpoint = true
      provider_installation {
        filesystem_mirror {
          path    = "/home/ec2-user/.terraform.d/plugins"
        }
      }
    path: /home/ec2-user/.terraformrc
    permissions: '0644'
    owner: ec2-user:ec2-user
  - content: |
      disable_checkpoint = true
      provider_installation {
        filesystem_mirror {
          path    = "/root/.terraform.d/plugins"
        }
      }
    path: /root/.terraformrc
    permissions: '0644'
    owner: root:root
EOF

}

data "template_file" "chown_home_directory" {
  template = <<EOF
runcmd:
  - echo "Chowning ~/ec2-user"
  - chown -R ec2-user:ec2-user ~ec2-user/
EOF

}

#
# Force the mount to occur during the "bootcmd".
# else the user directories are created before the fs is mounted, and nobody can login.
#
data "template_file" "home_directory" {
  template = <<EOF
bootcmd:
  - |
    set -ex
    while [ ! -e /dev/sdf ] ; do echo "Waiting for device /dev/sdf"; sleep 1 ; done
    if [ "$(file -b -s -L /dev/sdf)" == "data" ]; then mkfs -t ext4 /dev/sdf; fi
    mount -t ext4 -o 'defaults,nofail,comment=cloudconfig' /dev/sdf /home

mounts:
  - [ "/dev/sdf", "/home", "ext4", "defaults,nofail", "0", "2" ]

EOF
}

module "syslog_config" {
  source = "../../modules/syslog"

  root_domain    = local.root_domain
  syslog_ca_cert = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs

  role_name          = "sjb"
  public_bucket_name = data.terraform_remote_state.paperwork.outputs.public_bucket_name
  public_bucket_url  = data.terraform_remote_state.paperwork.outputs.public_bucket_url
}

data "template_cloudinit_config" "user_data" {
  base64_encode = true
  gzip          = true

  part {
    filename     = "config.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.home_directory.rendered
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

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
    filename     = "tag_completion.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.completion_tag_user_data
  }
}

resource "aws_ebs_volume" "sjb_home" {
  availability_zone = var.singleton_availability_zone
  size              = 60
  encrypted         = true
  kms_key_id        = data.terraform_remote_state.paperwork.outputs.kms_key_arn
}

module "sjb" {
  instance_count       = 1
  source               = "../../modules/launch"
  availability_zone    = var.singleton_availability_zone
  ami_id               = data.terraform_remote_state.paperwork.outputs.amzn_ami_id
  user_data            = data.template_cloudinit_config.user_data.rendered
  eni_ids              = data.terraform_remote_state.bootstrap_control_plane.outputs.sjb_eni_ids
  iam_instance_profile = data.terraform_remote_state.paperwork.outputs.sjb_role_name
  instance_types       = data.terraform_remote_state.scaling-params.outputs.instance_types
  volume_ids           = [aws_ebs_volume.sjb_home.id]
  scale_vpc_key        = "control-plane"
  scale_service_key    = "sjb"
  tags                 = local.modified_tags
  bot_key_pem          = data.terraform_remote_state.paperwork.outputs.bot_private_key
  check_cloud_init     = false
}
