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

data "terraform_remote_state" "bootstrap_bind" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "bootstrap_bind"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

locals {
  env_name                   = "${var.tags["Name"]}"
  modified_name              = "${local.env_name} bind"
  modified_tags              = "${merge(var.tags, map("Name", "${local.modified_name}"))}"
  bind_rndc_secret           = "${data.terraform_remote_state.bootstrap_bind.bind_rndc_secret}"
  master_private_ip          = "${data.terraform_remote_state.bootstrap_bind.bind_eni_ips[0]}"
  bind_master_data_volume_id = "${data.terraform_remote_state.bootstrap_bind.bind_master_data_volume_id}"

  root_domain = "${data.terraform_remote_state.paperwork.root_domain}"

  // If internetless = true in the bootstrap_bind layer,
  // eip_ips will be empty, and master_public_ip becomes the first eni_ip
  master_public_ip = "${element(concat(data.terraform_remote_state.bootstrap_bind.bind_eip_ips, data.terraform_remote_state.bootstrap_bind.bind_eni_ips), 0)}"

  slave_ips        = "${concat(data.terraform_remote_state.bootstrap_bind.bind_eip_ips, data.terraform_remote_state.bootstrap_bind.bind_eni_ips)}"
  slave_public_ips = ["${element(local.slave_ips, 1)}", "${element(local.slave_ips, 2)}"]
}

module "amazon_ami" {
  source = "../../modules/amis/encrypted/amazon2/lookup"
}

module "bind_host_key_pair" {
  source   = "../../modules/key_pair"
  key_name = "${local.modified_name}"
}

variable "user_data_path" {}

data "template_cloudinit_config" "master_bind_conf_userdata" {
  base64_encode = true
  gzip          = true

  part {
    filename     = "syslog.cfg"
    content      = "${module.syslog_config.user_data}"
    content_type = "text/x-include-url"
  }

  part {
    filename     = "master_bind_conf.cfg"
    content_type = "text/cloud-config"
    content      = "${module.bind_master_user_data.user_data}"
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

module "bind_master_user_data" {
  source      = "../../modules/bind_dns/master/user_data"
  client_cidr = "${var.client_cidr}"
  master_ip   = "${local.master_public_ip}"
  secret      = "${local.bind_rndc_secret}"
  slave_ips   = "${local.slave_public_ips}"
  zone_name   = "${local.root_domain}"
}

module "bind_master_host" {
  instance_count = 1
  source         = "../../modules/launch"
  ami_id         = "${module.amazon_ami.id}"
  user_data      = "${data.template_cloudinit_config.master_bind_conf_userdata.rendered}"
  eni_ids        = "${data.terraform_remote_state.bootstrap_bind.bind_eni_ids}"
  key_pair_name  = "${module.bind_host_key_pair.key_name}"
  tags           = "${local.modified_tags}"
}

resource "aws_volume_attachment" "bind_master_data_volume_attachment" {
  skip_destroy = true
  device_name  = "/dev/sdf"
  instance_id  = "${module.bind_master_host.instance_ids[0]}"
  volume_id    = "${local.bind_master_data_volume_id}"
}

module "syslog_config" {
  source                = "../../modules/syslog"
  root_domain           = "${local.root_domain}"
  splunk_syslog_ca_cert = "${data.terraform_remote_state.paperwork.trusted_ca_certs}"

  role_name          = "bind"
  public_bucket_name = "${data.terraform_remote_state.paperwork.public_bucket_name}"
  public_bucket_url  = "${data.terraform_remote_state.paperwork.public_bucket_url}"
}

data "template_cloudinit_config" "slave_bind_conf_userdata" {
  base64_encode = true
  gzip          = true

  part {
    filename     = "syslog.cfg"
    content      = "${module.syslog_config.user_data}"
    content_type = "text/x-include-url"
  }

  part {
    filename     = "slave_bind_conf.cfg"
    content_type = "text/cloud-config"
    content      = "${module.bind_slave_user_data.user_data}"
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

module "bind_slave_user_data" {
  source      = "../../modules/bind_dns/slave/user_data"
  client_cidr = "${var.client_cidr}"
  master_ip   = "${local.master_public_ip}"
  zone_name   = "${local.root_domain}"
}

module "bind_slave_host" {
  instance_count = "${length(data.terraform_remote_state.bootstrap_bind.bind_eni_ids) - 1}"
  source         = "../../modules/launch"
  ami_id         = "${module.amazon_ami.id}"
  user_data      = "${data.template_cloudinit_config.slave_bind_conf_userdata.rendered}"
  eni_ids        = ["${data.terraform_remote_state.bootstrap_bind.bind_eni_ids[1]}", "${data.terraform_remote_state.bootstrap_bind.bind_eni_ids[2]}"]
  key_pair_name  = "${module.bind_host_key_pair.key_name}"
  tags           = "${local.modified_tags}"
}

resource "null_resource" "wait_for_master" {
  triggers = {
    instance_id = "${module.bind_master_host.instance_ids[0]}"
  }

  provisioner "local-exec" {
    command = "while ! nslookup -timeout=1 -querytype=soa ${local.root_domain} ${local.master_public_ip} < /dev/null; do sleep 1; done"
  }
}

variable "remote_state_region" {}
variable "remote_state_bucket" {}

variable "tags" {
  type = "map"
}

output "bind_ssh_private_key" {
  value     = "${module.bind_host_key_pair.private_key_pem}"
  sensitive = true
}

output "master_private_ip" {
  value = "${local.master_private_ip}"
}

output "master_public_ip" {
  value = "${local.master_public_ip}"
}

variable "client_cidr" {}
