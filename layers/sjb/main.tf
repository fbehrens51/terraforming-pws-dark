provider "aws" {}

module "providers" {
  source = "../../modules/dark_providers"
}

terraform {
  backend "s3" {}
}

locals {
  env_name      = "${var.tags["Name"]}"
  modified_name = "${local.env_name} sjb"
  modified_tags = "${merge(var.tags, map("Name", "${local.modified_name}"))}"

  root_domain = "${data.terraform_remote_state.paperwork.root_domain}"
}

module "find_ami" {
  source = "../../modules/amis/encrypted/amazon2/lookup"
}

data "template_file" "setup_source_zip" {
  template = <<EOF
runcmd:
  - echo "Downloading and extracting source.zip"
  - mkdir /home/ec2-user/workspace
  - cd /home/ec2-user/workspace
  - |
    latest=$$(aws s3 ls s3://pws-dark-releases/ | grep ' source-code' | egrep '.zip$' | awk '{print $4}' | sort -n | tail -1)
    aws s3 cp s3://${var.product_blobs_s3_bucket}/$$latest --region ${var.product_blobs_s3_region} .
  - unzip source-code-*.zip
  - rm source-code-*.zip
EOF
}

data "template_file" "setup_system_tools" {
  template = <<EOF
runcmd:
  - echo "Installing up system tools and utilities"
  - yum install jq git python-pip -y
  - pip install yq
EOF
}

data "template_file" "setup_tools_zip" {
  template = <<EOF
runcmd:
  - echo "Downloading and extracting tools.zip"
  - |
    latest=$$(aws s3 ls s3://pws-dark-releases/ | grep ' tools' | egrep '.zip$' | awk '{print $4}' | sort -n | tail -1)
    aws s3 cp s3://${var.product_blobs_s3_bucket}/$$latest --region ${var.product_blobs_s3_region} .
  - unzip tools-*.zip
  - rm tools-*.zip
  - mkdir -p /home/ec2-user/.terraform.d/plugins/linux_amd64/
  - mv tools/terraform-provider* /home/ec2-user/.terraform.d/plugins/linux_amd64/.
  - mv tools/* /usr/local/bin/.
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

  root_domain = "${local.root_domain}"
}

data "template_cloudinit_config" "user_data" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "syslog.cfg"
    content_type = "text/cloud-config"
    content      = "${module.syslog_config.user_data}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  # source.zip
  part {
    filename     = "source_code_zip.cfg"
    content_type = "text/cloud-config"
    content      = "${data.template_file.setup_source_zip.rendered}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "tools_zip.cfg"
    content_type = "text/cloud-config"
    content      = "${data.template_file.setup_tools_zip.rendered}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "system_tools.cfg"
    content_type = "text/cloud-config"
    content      = "${data.template_file.setup_system_tools.rendered}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "chown_home_dir.cfg"
    content_type = "text/cloud-config"
    content      = "${data.template_file.chown_home_directory.rendered}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "other.cfg"
    content_type = "text/cloud-config"
    content      = "${file("${var.user_data_path}")}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "clamav.cfg"
    content_type = "text/cloud-config"
    content      = "${module.clam_av_client_config.client_user_data_config}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }
}

data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "paperwork"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_control_plane" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "bootstrap_control_plane"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

variable "clamav_db_mirror" {}
variable "custom_clamav_yum_repo_url" {}

module "clam_av_client_config" {
  source           = "../../modules/clamav/amzn2_systemd_client"
  clamav_db_mirror = "${var.clamav_db_mirror}"
  custom_repo_url  = "${var.custom_clamav_yum_repo_url}"
}

module "sjb" {
  instance_count       = 1
  source               = "../../modules/launch"
  ami_id               = "${module.find_ami.id}"
  user_data            = "${data.template_cloudinit_config.user_data.rendered}"
  eni_ids              = "${data.terraform_remote_state.bootstrap_control_plane.sjb_eni_ids}"
  key_pair_name        = "${data.terraform_remote_state.bootstrap_control_plane.sjb_ssh_key_pair_name}"
  iam_instance_profile = "${data.terraform_remote_state.paperwork.sjb_role_name}"
  instance_type        = "${var.instance_type}"
  ssh_banner           = "${data.terraform_remote_state.paperwork.custom_ssh_banner}"

  tags = "${merge(local.modified_tags, map("Name", "${local.env_name}-sjb"))}"

  root_block_device = {
    volume_type = "gp2"
    volume_size = 64
  }
}