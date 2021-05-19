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
  secret_bucket_name    = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
  transfer_bucket_name  = data.terraform_remote_state.bootstrap_control_plane.outputs.transfer_bucket_name
  terraform_bucket_name = data.terraform_remote_state.bootstrap_control_plane.outputs.terraform_bucket_name
  ldap_dn               = data.terraform_remote_state.paperwork.outputs.ldap_dn
  ldap_port             = data.terraform_remote_state.paperwork.outputs.ldap_port
  ldap_host             = data.terraform_remote_state.paperwork.outputs.ldap_host
  ldap_basedn           = data.terraform_remote_state.paperwork.outputs.ldap_basedn
  ldap_ca_cert          = data.terraform_remote_state.paperwork.outputs.ldap_ca_cert_s3_path
  ldap_client_cert      = data.terraform_remote_state.paperwork.outputs.ldap_client_cert_s3_path
  ldap_client_key       = data.terraform_remote_state.paperwork.outputs.ldap_client_key_s3_path
  pypi_protocol         = var.pypi_host_secure ? "https" : "http"
}

data "template_file" "setup_scripts" {
  template = <<EOF
write_files:
  - path: /etc/skel/bin/install-pcf-eagle-automation.sh
    permissions: '0755'
    owner: root:root
    content: |
      #!/usr/bin/env bash
      set -eo pipefail

      transfer=$transfer_bucket_name

      [[ ! -n $HOME ]] && HOME=root # HOME is not set during system boot.

      workspace="$HOME/workspace"
      [ ! -d $workspace ] && mkdir -p "$workspace"

      region="$( aws s3api get-bucket-location --output=text --bucket $transfer 2> /dev/null )"
      [[ $region == None ]] && region='us-east-1'

      function get_source() {
        artifact=$1
        artifact_dir="$workspace/$artifact"
        # regex matches a valid semver - from semver.org
        latest=$(aws --region $region s3 ls s3://$transfer/$artifact/ \
                 | grep -Po "($artifact-(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?\.zip)$" \
                 | sort -V \
                 | tail -n 1 \
                )
        aws --region $region s3 cp --no-progress s3://$transfer/$artifact/$latest . --no-progress
        [ ! -d $artifact_dir ] && mkdir -p "$artifact_dir"
        unzip -q -d "$artifact_dir" "$latest"
        rm "$latest"
      }

      get_source "pcf-eagle-automation"

  - path: /etc/profile.d/tws_env.sh
    permissions: '0644'
    owner: root:root
    content: |
      # File contents are created via terraform, do not edit manually.
      export terraform_bucket_name="${local.terraform_bucket_name}"
      export transfer_bucket_name="${local.transfer_bucket_name}"
      export secret_bucket_name="${local.secret_bucket_name}"
      export git_host="${var.git_host}"
      export credhub_vars_name="${var.credhub_vars_name}"
      export env_repo_name="${var.env_repo_name}"
      export root_domain="${local.root_domain}"
      export cp_target_name="${var.cp_target_name}"
      export ldap_dn="${local.ldap_dn}"
      export ldap_port="${local.ldap_port}"
      export ldap_host="${local.ldap_host}"
      export ldap_basedn="${local.ldap_basedn}"
      export ldap_ca_cert="${local.ldap_ca_cert}"
      export ldap_client_cert="${local.ldap_client_cert}"
      export ldap_client_key="${local.ldap_client_key}"
      export AWS_DEFAULT_REGION="${var.region}"

runcmd:
  - |
    # echo "Installing up system tools and utilities"
    yum install jq git python-pip python3 openldap-clients -y
    pip3 install yq --index-url=${local.pypi_protocol}://${var.pypi_host}/simple --trusted-host=${var.pypi_host}

    # set the home dirs to proper owners - users are recreated every time the vm is created, and the home dirs are persisted.
    # If a user is added or deleted, that will break ownership of home dirs
    awk -F: '$3 ~ /1[0-9]{3,3}/{ print "chown -R " $3 ":" $4 " " $6}' /etc/passwd | xargs --no-run-if-empty -0 sh -c
    transfer_bucket_name="${local.transfer_bucket_name}"   /etc/skel/bin/install-pcf-eagle-automation.sh
    transfer_bucket_name="${local.transfer_bucket_name}"   /root/workspace/pcf-eagle-automation/scripts/sjb/install-cli-tools.sh
    terraform_bucket_name="${local.terraform_bucket_name}" HOME="/root" /root/workspace/pcf-eagle-automation/scripts/sjb/install-terraform.sh
    root_domain="${local.root_domain}"                     /root/workspace/pcf-eagle-automation/scripts/sjb/install-fly.sh
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
    if mountpoint -q /home; then
      umount /home
      sed -i '/^\/dev\/vg0\/home/d' /etc/fstab
    fi
    mount -t ext4 -o 'defaults,nofail,nodev,comment=TF_user_data' /dev/sdf /home
    install -m 755 -d /etc/skel/bin

mounts:
  - [ "/dev/sdf", "/home", "ext4", "defaults,nofail,nodev", "0", "2" ]

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

  part {
    filename     = "terraform_zip.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.setup_scripts.rendered
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
    filename     = "hardening.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.server_hardening_user_data
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
  // TODO: change to sjb_role_name
  iam_instance_profile = data.terraform_remote_state.paperwork.outputs.sjb_role_name
  instance_types       = data.terraform_remote_state.scaling-params.outputs.instance_types
  volume_ids           = [aws_ebs_volume.sjb_home.id]
  scale_vpc_key        = "control-plane"
  scale_service_key    = "sjb"
  tags                 = local.modified_tags
  bot_key_pem          = data.terraform_remote_state.paperwork.outputs.bot_private_key
  check_cloud_init     = false
}

resource "null_resource" "sjb_status" {
  count = 1
  triggers = {
    instance_id = module.sjb.instance_ids[count.index]
  }

  provisioner "local-exec" {
    on_failure  = fail
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOF
    #!/usr/bin/env bash
    set -e
    completed_tag="cloud_init_done"
    poll_tags="aws ec2 describe-tags --filters Name=resource-id,Values=${module.sjb.instance_ids[count.index]} Name=key,Values=$completed_tag --output text --query Tags[*].Value"
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
