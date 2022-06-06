locals {
  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} sjb"
  modified_tags = merge(
    var.global_vars["global_tags"],
    var.global_vars["instance_tags"],
    {
      "Name"            = local.modified_name
      "MetricsKey"      = data.terraform_remote_state.paperwork.outputs.metrics_key
      "foundation_name" = data.terraform_remote_state.paperwork.outputs.foundation_name
      "job"             = "sjb"
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

data "terraform_remote_state" "bootstrap_sjb" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_sjb"
    region  = var.remote_state_region
    encrypt = true
  }
}

locals {
  release_channel             = data.terraform_remote_state.paperwork.outputs.release_channel
  secret_bucket_name          = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
  artifact_repo_bucket_name   = data.terraform_remote_state.paperwork.outputs.artifact_repo_bucket_name
  artifact_repo_bucket_region = data.terraform_remote_state.paperwork.outputs.artifact_repo_bucket_region
  terraform_bucket_name       = data.terraform_remote_state.bootstrap_sjb.outputs.terraform_bucket_name
  ldap_dn                     = data.terraform_remote_state.paperwork.outputs.ldap_dn
  ldap_port                   = data.terraform_remote_state.paperwork.outputs.ldap_port
  ldap_host                   = data.terraform_remote_state.paperwork.outputs.ldap_host
  ldap_basedn                 = data.terraform_remote_state.paperwork.outputs.ldap_basedn
  ldap_ca_cert                = data.terraform_remote_state.paperwork.outputs.ldap_ca_cert_s3_path
  ldap_client_cert            = data.terraform_remote_state.paperwork.outputs.ldap_client_cert_s3_path
  ldap_client_key             = data.terraform_remote_state.paperwork.outputs.ldap_client_key_s3_path
  pypi_protocol               = var.pypi_host_secure ? "https" : "http"
}

data "template_file" "setup_scripts" {
  template = <<EOF
write_files:
  - path: /usr/local/bin/install-pwsd.sh
    permissions: '0755'
    owner: root:root
    content: |
      #!/usr/bin/env bash
      set -exo pipefail

      [[ ! -n $HOME ]] && HOME=/root # HOME is not set during system boot.

      bucket="${local.artifact_repo_bucket_name}"
      user="$(id -nu)"

      [[ $user != root ]] && INSTALL="sudo install" || INSTALL="install"

      echo "Downloading and extracting tools.zip"

      region="$( aws s3api get-bucket-location --output=text --bucket $bucket 2> /dev/null )"
      [[ $region == None ]] && region='us-east-1'

      latest="$(aws --region $region s3 ls s3://$bucket/cli-tools/ | awk '/ tools.*\.zip$/ {print $4}' | sort -n | tail -1)"
      aws --region "$region" s3 cp "s3://$bucket/cli-tools/$latest" . --no-progress

      unzip -q "$latest" tools/pwsd
      $INSTALL tools/* /usr/local/bin/
      rm -rf "$latest" tools

  - path: /usr/local/bin/install-artifact.sh
    permissions: '0755'
    owner: root:root
    content: |
      #!/usr/bin/env bash
      set -exo pipefail

      [[ ! -n $HOME ]] && HOME=/root # HOME is not set during system boot.

      workspace="$HOME/workspace"
      [ ! -d $workspace ] && mkdir -p "$workspace"

      function get_source() {
        local artifact=$1
        local local_repo="$workspace/artifacts"
        local artifact_dir="$workspace/$artifact"

       if [[ ! -d $artifact_dir ]]; then
         mkdir -p "$artifact_dir"
       else
         echo "Artifact directory exists: $artifact; please remove/rename and try again"
         exit 1
       fi

        /usr/local/bin/pwsd release download --components "$artifact" --output "$local_repo"
        unzip -q -d "$artifact_dir" "$local_repo/$artifact/*.zip"

        rm -r "$local_repo"
      }

      for artifact in "$@"; do
        get_source $artifact
      done

  - path: /etc/profile.d/tws_env.sh
    permissions: '0644'
    owner: root:root
    content: |
      # File contents are created via terraform, do not edit manually.
      export terraform_bucket_name="${local.terraform_bucket_name}"
      export PWSD_ARTIFACT_REPO="s3://${local.artifact_repo_bucket_name}"
      export PWSD_ARTIFACT_REPO_REGION="${local.artifact_repo_bucket_region}"
      export PWSD_CHANNEL_NAME="${local.release_channel}"
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
      export AWS_REGION="${var.region}"
      export AWS_DEFAULT_REGION="${var.region}"
      export TF_PWS_DARK_REPO=$HOME/workspace/terraforming-pws-dark
      export PATH=/usr/local/bin:$PATH

runcmd:
  - |
    # echo "Installing up system tools and utilities"
    yum install jq git python-pip python3 openldap-clients -y
    pip3 install yq --index-url=${local.pypi_protocol}://${var.pypi_host}/simple --trusted-host=${var.pypi_host}

    export AWS_REGION=${var.region}
    export AWS_DEFAULT_REGION=${var.region}
    export PWSD_ARTIFACT_REPO="s3://${local.artifact_repo_bucket_name}"
    export PWSD_ARTIFACT_REPO_REGION="${local.artifact_repo_bucket_region}"
    export PWSD_CHANNEL_NAME="${local.release_channel}"
    export root_domain="${local.root_domain}"

    PATH=/usr/local/bin:$PATH
    export HOME=/var/root
    install -d $HOME
    install-pwsd.sh
    install-artifact.sh pcf-eagle-automation cli-tools
    $HOME/workspace/pcf-eagle-automation/scripts/sjb/install-fly.sh
    $HOME/workspace/pcf-eagle-automation/scripts/sjb/install-cli-tools.sh
    rm -rf $HOME

    # human users UIDs start at 1000
    for user in $(awk -F: '$3 ~ /1[0-9]{3,3}/{print $1}' /etc/passwd | sort | grep -Ev 'ec2-user|security_scanner' ); do
      home="$( awk -v user=$user -F: '$1 == user { print $6 }' /etc/passwd )"
      sudo -u $user PATH=$PATH -i install-artifact.sh pcf-eagle-automation
      sudo -u $user PATH=$PATH -i $home/workspace/pcf-eagle-automation/scripts/sjb/setup_user.sh
    done
EOF
}

data "template_file" "home_directory" {
  template = <<EOF
bootcmd:
  - |
    set -ex
    growpart /dev/nvme0n1 2
    pvresize /dev/nvme0n1p2
    lvextend -r -l +100%FREE /dev/vg0/home
EOF
}

module "syslog_config" {
  source = "../../modules/syslog"

  root_domain    = local.root_domain
  syslog_ca_cert = data.terraform_remote_state.paperwork.outputs.syslog_ca_certs_bundle

  role_name          = "sjb"
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
    filename     = "system_certs.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.amazon2_system_certs_user_data
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
    filename     = "iptables.cfg"
    content_type = "text/cloud-config"
    content      = module.iptables_rules.iptables_user_data
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "dnsmasq.cfg"
    content_type = "text/cloud-config"
    content      = module.dnsmasq.dnsmasq_user_data
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

data "aws_vpc" "vpc" {
  id = data.terraform_remote_state.paperwork.outputs.cp_vpc_id
}

module "dnsmasq" {
  source         = "../../modules/dnsmasq"
  enterprise_dns = data.terraform_remote_state.paperwork.outputs.enterprise_dns
  forwarders = [{
    domain        = var.endpoint_domain
    forwarder_ips = [cidrhost(data.aws_vpc.vpc.cidr_block, 2)]
    },
    {
      domain        = ""
      forwarder_ips = data.terraform_remote_state.paperwork.outputs.enterprise_dns
    }
  ]
}

module "iptables_rules" {
  source                     = "../../modules/iptables"
  control_plane_subnet_cidrs = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_cidrs
}

module "sjb" {
  instance_count       = 1
  source               = "../../modules/launch"
  availability_zone    = var.singleton_availability_zone
  ami_id               = data.terraform_remote_state.paperwork.outputs.amzn_ami_id
  user_data            = data.template_cloudinit_config.user_data.rendered
  eni_ids              = data.terraform_remote_state.bootstrap_sjb.outputs.sjb_eni_ids
  iam_instance_profile = data.terraform_remote_state.paperwork.outputs.bootstrap_role_name
  instance_types       = data.terraform_remote_state.scaling-params.outputs.instance_types
  scale_vpc_key        = "control-plane"
  scale_service_key    = "sjb"
  tags                 = local.modified_tags
  bot_key_pem          = data.terraform_remote_state.paperwork.outputs.bot_private_key
  check_cloud_init     = true
  cloud_init_timeout   = var.cloud_init_timeout
  operating_system     = data.terraform_remote_state.paperwork.outputs.amazon_operating_system_tag

  root_block_device = {
    tags = { "Name" = "${local.modified_name} root" }
    volume_size = var.home_volume_size
    encrypted   = true
    kms_key_id  = data.terraform_remote_state.paperwork.outputs.kms_key_arn
    volume_type = "gp2"
  }
}

output "ssh_host_ips" {
  value = zipmap(flatten(module.sjb.ssh_host_names), flatten(module.sjb.private_ips))
}
