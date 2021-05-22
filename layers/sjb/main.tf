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
  secrets_bucket_name   = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
  transfer_bucket_name  = data.terraform_remote_state.bootstrap_control_plane.outputs.transfer_bucket_name
  terraform_bucket_name = data.terraform_remote_state.bootstrap_control_plane.outputs.terraform_bucket_name
  terraform_region      = data.terraform_remote_state.bootstrap_control_plane.outputs.terraform_region
  system_domain         = data.terraform_remote_state.paperwork.outputs.root_domain
  # the six spaces after the "\n" is the required indent for the yaml 'write_files: -> content:' section
  get_source = join("\n      ", [for artifact in var.source_artifacts : "get_source ${artifact}"])

  ldap_dn          = data.terraform_remote_state.paperwork.outputs.ldap_dn
  ldap_port        = data.terraform_remote_state.paperwork.outputs.ldap_port
  ldap_host        = data.terraform_remote_state.paperwork.outputs.ldap_host
  ldap_basedn      = data.terraform_remote_state.paperwork.outputs.ldap_basedn
  ldap_ca_cert     = data.terraform_remote_state.paperwork.outputs.ldap_ca_cert_s3_path
  ldap_client_cert = data.terraform_remote_state.paperwork.outputs.ldap_client_cert_s3_path
  ldap_client_key  = data.terraform_remote_state.paperwork.outputs.ldap_client_key_s3_path
}

data "template_file" "setup_system_tools" {
  template = <<EOF
runcmd:
  - echo "Installing up system tools and utilities"
  - yum install jq git python-pip python3 openldap-clients -y
  - pip3 install yq --index-url=$${pypi_host_protocol}://$${pypi_host}/simple --trusted-host=$${pypi_host}
EOF

  vars = {
    pypi_host          = var.pypi_host
    pypi_host_protocol = var.pypi_host_secure ? "https" : "http"
  }
}

data "template_file" "setup_scripts" {
  template = <<EOF
runcmd:
  - |
    # set the home dirs to proper owners - users are recreated every time the vm is created, and the home dirs are persisted.
    # If a user is added or deleted, that will break ownership of home dirs
    awk -F: '$3 ~ /1[0-9]{3,3}/{ print "chown -R " $3 ":" $4 " " $6}' /etc/passwd | xargs --no-run-if-empty -0 sh -c
write_files:
  - path: /etc/skel/.hushlogin
    permissions: '0755'
    owner: root:root

  - path: /etc/skel/bin/write_ldaprc.sh
    permissions: '0755'
    owner: root:root
    content: |
      #!/usr/bin/env bash
      set -eo pipefail

      certs="$HOME/certs"
      ldaprc="$HOME/.ldaprc"

      [[ ! -d $certs ]] && mkdir "$certs"
      aws --region ${var.region} s3 ls s3://${local.secrets_bucket_name} | awk '/ldap.*pem/ { print $4}' | xargs --no-run-if-empty -I{} aws --region ${var.region} s3 cp s3://${local.secrets_bucket_name}/{} "$certs"

      echo -e "URI ldaps://${local.ldap_host}:${local.ldap_port}\nBASE ${local.ldap_basedn}\nBINDDN ${local.ldap_dn}\nDEREF never\nSASL_MECH EXTERNAL\nTLS_CACERT $certs/${local.ldap_ca_cert}\nTLS_CERT $certs/${local.ldap_client_cert}\nTLS_KEY $certs/${local.ldap_client_key}" > "$ldaprc"

  - path: /etc/skel/bin/write_flyrc.sh
    permissions: '0755'
    owner: root:root
    content: |
      #!/usr/bin/env bash

      flyrc="$HOME/.flyrc"
      [ ! -e $flyrc ] && echo -e "targets:\n  ${var.cp_target_name}:\n    api: https://plane.ci.${local.system_domain}\n    insecure: true\n    team: main" > "$flyrc"

  - path: /etc/skel/bin/write_terraformrc.sh
    permissions: '0755'
    owner: root:root
    content: |
      #!/usr/bin/env bash

      terraformrc="$HOME/.terraformrc"
      plugin_dir="$HOME/.terraform.d"
      [ ! -d $plugin_dir ] && mkdir "$plugin_dir"
      [ ! -e $terraformrc ] && echo -e "disable_checkpoint = true\nprovider_installation {\n  filesystem_mirror {\n    path = \"$plugin_dir\"\n  }\n}" > "$terraformrc"

  - path: /etc/skel/bin/install-cli-tools.sh
    permissions: '0755'
    owner: root:root
    content: |
      #!/usr/bin/env bash
      set -eo pipefail
      [[ $(id -nu ) != root ]] && INSTALL="sudo install" || INSTALL="install"

      echo "Downloading and extracting tools.zip"

      latest=$(aws --region ${var.region} s3 ls s3://${local.transfer_bucket_name}/cli-tools/ | awk '/ tools.*\.zip$/ {print $4}' | sort -n | tail -1)
      aws --region ${var.region} s3 cp s3://${local.transfer_bucket_name}/cli-tools/$latest . --no-progress

      unzip -q $latest
      $INSTALL tools/* /usr/local/bin/
      rm -rf $latest tools

  - path: /etc/skel/bin/install-terraform.sh
    permissions: '0755'
    owner: root:root
    content: |
      #!/usr/bin/env bash
      set -eo pipefail
      [[ $(id -nu ) != root ]] && INSTALL="sudo install" || INSTALL="install"

      echo "Downloading and extracting terraform.zip"
      TF="$HOME/terraform"
      mkdir $TF

      latest=$(aws --region ${local.terraform_region} s3 ls s3://${local.terraform_bucket_name}/terraform-bundle/ | awk '/ terraform-bundle.*\.zip$/ {print $4}' | sort -n | tail -1)
      aws --region ${local.terraform_region} s3 cp s3://${local.terraform_bucket_name}/terraform-bundle/$latest . --no-progress

      unzip -q -d "$TF" $latest
      plugin_dir="$HOME/.terraform.d"

      [ ! -d $plugin_dir ] && mkdir "$plugin_dir"

      cp -pr "$TF/plugins" "$HOME/.terraform.d/"
      $INSTALL "$TF/terraform" /usr/local/bin/

      rm -rf "$latest" "$TF"

  - path: /etc/skel/bin/install-source.sh
    permissions: '0755'
    owner: root:root
    content: |
      #!/usr/bin/env bash
      set -eo pipefail

      echo "Downloading and extracting sources"

      workspace="$HOME/workspace"
      [ ! -d $workspace ] && mkdir -p "$workspace"

      function get_source() {
        artifact=$1
        artifact_dir="$workspace/$artifact"
        # regex matches a valid semver - from semver.org
        latest=$(aws --region us-east-2 s3 ls s3://${local.transfer_bucket_name}/$artifact/ \
                 | grep -Po "($artifact-(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?\.zip)$" \
                 | sort -V \
                 | tail -n 1 \
                )
        aws --region us-east-2 s3 cp --no-progress s3://${local.transfer_bucket_name}/$artifact/$latest . --no-progress
        [ ! -d $artifact_dir ] && mkdir -p "$artifact_dir"
        unzip -q -d "$artifact_dir" "$latest"
        rm "$latest"
      }

      ${local.get_source}
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

  part {
    filename     = "terraform_zip.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.setup_scripts.rendered
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "system_tools.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.setup_system_tools.rendered
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
