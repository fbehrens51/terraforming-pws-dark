terraform {
  backend "s3" {}
}

provider "aws" {}

module "providers" {
  source = "../../modules/dark_providers"
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

data "terraform_remote_state" "bootstrap_postfix" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "bootstrap_postfix"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

data "terraform_remote_state" "encrypt_amis" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "encrypt_amis"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

locals {
  env_name      = "${var.tags["Name"]}"
  modified_name = "${local.env_name} postfix"
  modified_tags = "${merge(var.tags, map("Name", "${local.modified_name}"))}"

  encrypted_amazon2_ami_id = "${data.terraform_remote_state.encrypt_amis.encrypted_amazon2_ami_id}"

  root_domain = "${data.terraform_remote_state.paperwork.root_domain}"

  postfix_ip = "${data.terraform_remote_state.bootstrap_postfix.postfix_eni_ips[0]}"
  smtp_user  = "${data.terraform_remote_state.bootstrap_postfix.smtp_client_user}"
  smtp_pass  = "${data.terraform_remote_state.bootstrap_postfix.smtp_client_password}"
}

module "postfix_host_key_pair" {
  source   = "../../modules/key_pair"
  key_name = "${local.modified_name}"
}

module "configuration" {
  source = "modules/config"

  public_bucket_name  = "${data.terraform_remote_state.paperwork.public_bucket_name}"
  public_bucket_url   = "${data.terraform_remote_state.paperwork.public_bucket_url}"
  smtp_relay_host     = "${var.smtp_relay_host}"
  smtp_relay_port     = "${data.terraform_remote_state.bootstrap_postfix.smtp_relay_port}"
  smtp_relay_username = "${var.smtp_relay_username}"
  smtp_relay_password = "${data.terraform_remote_state.paperwork.smtp_relay_password}"
  smtp_relay_ca_cert  = "${data.terraform_remote_state.paperwork.smtp_relay_ca_cert}"
  smtpd_server_cert   = "${data.terraform_remote_state.paperwork.smtpd_server_cert}"
  smtpd_server_key    = "${data.terraform_remote_state.paperwork.smtpd_server_key}"
  smtpd_cidr_blocks   = ["${data.aws_vpc.es_vpc.cidr_block}", "${data.aws_vpc.pas_vpc.cidr_block}"]
  smtp_user           = "${local.smtp_user}"
  smtp_pass           = "${local.smtp_pass}"
  root_domain         = "${local.root_domain}"
}

data "aws_vpc" "es_vpc" {
  id = "${data.terraform_remote_state.paperwork.es_vpc_id}"
}

data "aws_vpc" "pas_vpc" {
  id = "${data.terraform_remote_state.paperwork.pas_vpc_id}"
}

data "template_cloudinit_config" "user_data" {
  base64_encode = true
  gzip          = true

  part {
    filename     = "syslog.cfg"
    content      = "${module.syslog_config.user_data}"
    content_type = "text/x-include-url"
  }

  part {
    filename     = "certs.cfg"
    content      = "${module.configuration.certs_user_data}"
    content_type = "text/x-include-url"
  }

  part {
    filename     = "config.cfg"
    content_type = "text/cloud-config"
    content      = "${module.configuration.config_user_data}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "clamav.cfg"
    content_type = "text/x-include-url"
    content      = "${data.terraform_remote_state.paperwork.amazon2_clamav_user_data}"
  }

  part {
    filename     = "user_accounts_user_data.cfg"
    content_type = "text/x-include-url"
    content      = "${data.terraform_remote_state.paperwork.user_accounts_user_data}"
  }

  part {
    filename     = "banner.cfg"
    content_type = "text/x-include-url"
    content      = "${data.terraform_remote_state.paperwork.custom_banner_user_data}"
  }
}

module "postfix_master_host" {
  instance_count = 1
  source         = "../../modules/launch"
  ami_id         = "${local.encrypted_amazon2_ami_id}"
  user_data      = "${data.template_cloudinit_config.user_data.rendered}"
  eni_ids        = "${data.terraform_remote_state.bootstrap_postfix.postfix_eni_ids}"
  key_pair_name  = "${module.postfix_host_key_pair.key_name}"
  tags           = "${local.modified_tags}"
}

module "syslog_config" {
  source                = "../../modules/syslog"
  root_domain           = "${local.root_domain}"
  splunk_syslog_ca_cert = "${data.terraform_remote_state.paperwork.trusted_ca_certs}"

  role_name          = "postfix"
  public_bucket_name = "${data.terraform_remote_state.paperwork.public_bucket_name}"
  public_bucket_url  = "${data.terraform_remote_state.paperwork.public_bucket_url}"
}
