provider "aws" {}

module "providers" {
  source = "../../modules/dark_providers"
}

terraform {
  backend "s3" {}
}

data "terraform_remote_state" "enterprise-services" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "enterprise-services"
    region  = "${var.remote_state_region}"
    encrypt = true
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

data "terraform_remote_state" "bootstrap_splunk" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "bootstrap_splunk"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

module "splunk_ports" {
  source = "../../modules/splunk_ports"
}

locals {
  splunk_master_eni_id      = "${data.terraform_remote_state.bootstrap_splunk.master_eni_ids[0]}"
  splunk_indexers_eni_ids   = "${data.terraform_remote_state.bootstrap_splunk.indexers_eni_ids}"
  splunk_forwarders_eni_ids = "${data.terraform_remote_state.bootstrap_splunk.forwarders_eni_ids}"
  splunk_search_head_eni_id = "${data.terraform_remote_state.bootstrap_splunk.search_head_eni_ids[0]}"

  splunk_http_collector_port = "${module.splunk_ports.splunk_http_collector_port}"
  splunk_mgmt_port           = "${module.splunk_ports.splunk_mgmt_port}"
  splunk_replication_port    = "${module.splunk_ports.splunk_replication_port}"
  splunk_indexers_input_port = "${module.splunk_ports.splunk_tcp_port}"
  splunk_syslog_port         = "${module.splunk_ports.splunk_tcp_port}"
  splunk_web_port            = "${module.splunk_ports.splunk_web_port}"

  tags = "${merge(var.tags, map("Name", "${var.env_name}-splunk"))}"

  splunk_role_name = "${data.terraform_remote_state.paperwork.splunk_role_name}"

  indexers_pass4SymmKey   = "${data.terraform_remote_state.bootstrap_splunk.indexers_pass4SymmKey}"
  forwarders_pass4SymmKey = "${data.terraform_remote_state.bootstrap_splunk.forwarders_pass4SymmKey}"

  master_ip = "${data.terraform_remote_state.bootstrap_splunk.master_private_ips[0]}"

  ssh_key_pair_name = "${data.terraform_remote_state.bootstrap_splunk.splunk_ssh_key_pair_name}"
}

variable "remote_state_bucket" {}
variable "remote_state_region" {}

variable "env_name" {}

variable "tags" {
  type = "map"
}

variable "splunk_rpm_version" {}
variable "splunk_rpm_s3_bucket" {}
variable "splunk_rpm_s3_region" {}

variable "instance_type" {
  default = "t2.small"
}

variable "user_data_path" {}
variable "license_path" {}

module "amazon_ami" {
  source = "../../modules/amis/amazon_hvm_ami"
}

module "insecure_web_conf" {
  source = "./modules/web-conf/insecure"

  web_port  = "${local.splunk_web_port}"
  mgmt_port = "${local.splunk_mgmt_port}"
}

module "search_head_web_conf" {
  source = "./modules/web-conf/secure"

  server_cert_content = "${data.terraform_remote_state.paperwork.splunk_server_cert}"
  server_key_content  = "${data.terraform_remote_state.paperwork.splunk_server_key}"
  web_port            = "${local.splunk_web_port}"
  mgmt_port           = "${local.splunk_mgmt_port}"
}

module "master_web_conf" {
  source = "./modules/web-conf/secure"

  server_cert_content = "${data.terraform_remote_state.paperwork.splunk_monitor_server_cert}"
  server_key_content  = "${data.terraform_remote_state.paperwork.splunk_monitor_server_key}"
  web_port            = "${local.splunk_web_port}"
  mgmt_port           = "${local.splunk_mgmt_port}"
}

module "master_server_conf" {
  source = "./modules/server-conf/master"

  indexers_pass4SymmKey   = "${local.indexers_pass4SymmKey}"
  forwarders_pass4SymmKey = "${local.forwarders_pass4SymmKey}"
}

module "setup_master_hostname" {
  source = "./modules/setup-hostname"
  role   = "splunk-master"
}

module "search_head_server_conf" {
  source = "./modules/server-conf/search-head"

  master_ip    = "${local.master_ip}"
  mgmt_port    = "${local.splunk_mgmt_port}"
  pass4SymmKey = "${local.indexers_pass4SymmKey}"
}

module "setup_search_head_hostname" {
  source = "./modules/setup-hostname"
  role   = "splunk-search-head"
}

module "setup_forwarders_hostname" {
  source = "./modules/setup-hostname"
  role   = "splunk-forwarder"
}

module "indexers_server_conf" {
  source = "./modules/server-conf/indexers"

  master_ip        = "${local.master_ip}"
  mgmt_port        = "${local.splunk_mgmt_port}"
  pass4SymmKey     = "${local.indexers_pass4SymmKey}"
  replication_port = "${local.splunk_replication_port}"
}

module "splunk_setup" {
  source = "./modules/splunk-setup"

  admin_password       = "${data.terraform_remote_state.bootstrap_splunk.splunk_password}"
  splunk_rpm_version   = "${var.splunk_rpm_version}"
  splunk_rpm_s3_bucket = "${var.splunk_rpm_s3_bucket}"
  splunk_rpm_s3_region = "${var.splunk_rpm_s3_region}"
}

module "indexers_inputs_conf" {
  source     = "./modules/inputs-and-outputs/indexers"
  input_port = "${local.splunk_indexers_input_port}"
}

module "forwardes_inputs_outputs_conf" {
  source = "./modules/inputs-and-outputs/forwarders"

  syslog_port         = "${local.splunk_syslog_port}"
  master_ip           = "${local.master_ip}"
  mgmt_port           = "${local.splunk_mgmt_port}"
  http_token          = "${data.terraform_remote_state.bootstrap_splunk.splunk_http_collector_token}"
  http_collector_port = "${local.splunk_http_collector_port}"
  pass4SymmKey        = "${local.forwarders_pass4SymmKey}"
}

module "slave_license_conf" {
  source = "./modules/license-conf/slave"

  master_ip = "${local.master_ip}"
  mgmt_port = "${local.splunk_mgmt_port}"
}

module "master_license_conf" {
  source = "./modules/license-conf/master"

  license_path = "${var.license_path}"
}

module "setup_indexers_hostname" {
  source = "./modules/setup-hostname"
  role   = "splunk-inexer"
}

data "template_cloudinit_config" "splunk_master_cloud_init_config" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "serverconf.cfg"
    content_type = "text/cloud-config"
    content      = "${module.master_server_conf.user_data}"
  }

  part {
    filename     = "webconf.cfg"
    content_type = "text/cloud-config"
    content      = "${module.master_web_conf.user_data}"
  }

  part {
    filename     = "setup-hostname.cfg"
    content_type = "text/cloud-config"
    content      = "${module.setup_master_hostname.user_data}"
  }

  part {
    filename     = "license.cfg"
    content_type = "text/cloud-config"
    content      = "${module.master_license_conf.user_data}"
  }

  part {
    filename     = "setup.cfg"
    content_type = "text/cloud-config"
    content      = "${module.splunk_setup.user_data}"
  }

  part {
    filename     = "custom.cfg"
    content_type = "text/cloud-config"
    content      = "${file(var.user_data_path)}"
  }
}

data "template_cloudinit_config" "splunk_search_head_cloud_init_config" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "serverconf.cfg"
    content_type = "text/cloud-config"
    content      = "${module.search_head_server_conf.user_data}"
  }

  part {
    filename     = "webconf.cfg"
    content_type = "text/cloud-config"
    content      = "${module.search_head_web_conf.user_data}"
  }

  part {
    filename     = "setup-hostname.cfg"
    content_type = "text/cloud-config"
    content      = "${module.setup_search_head_hostname.user_data}"
  }

  part {
    filename     = "license.cfg"
    content_type = "text/cloud-config"
    content      = "${module.slave_license_conf.user_data}"
  }

  part {
    filename     = "setup.cfg"
    content_type = "text/cloud-config"
    content      = "${module.splunk_setup.user_data}"
  }

  part {
    filename     = "custom.cfg"
    content_type = "text/cloud-config"
    content      = "${file(var.user_data_path)}"
  }
}

data "template_cloudinit_config" "splunk_forwarders_cloud_init_config" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "webconf.cfg"
    content_type = "text/cloud-config"
    content      = "${module.insecure_web_conf.user_data}"
  }

  part {
    filename     = "inputsconf.cfg"
    content_type = "text/cloud-config"
    content      = "${module.forwardes_inputs_outputs_conf.user_data}"
  }

  part {
    filename     = "setup-hostname.cfg"
    content_type = "text/cloud-config"
    content      = "${module.setup_forwarders_hostname.user_data}"
  }

  part {
    filename     = "license.cfg"
    content_type = "text/cloud-config"
    content      = "${module.slave_license_conf.user_data}"
  }

  part {
    filename     = "setup.cfg"
    content_type = "text/cloud-config"
    content      = "${module.splunk_setup.user_data}"
  }

  part {
    filename     = "custom.cfg"
    content_type = "text/cloud-config"
    content      = "${file(var.user_data_path)}"
  }
}

data "template_cloudinit_config" "splunk_indexers_cloud_init_config" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "serverconf.cfg"
    content_type = "text/cloud-config"
    content      = "${module.indexers_server_conf.user_data}"
  }

  part {
    filename     = "inputsconf.cfg"
    content_type = "text/cloud-config"
    content      = "${module.indexers_inputs_conf.user_data}"
  }

  part {
    filename     = "webconf.cfg"
    content_type = "text/cloud-config"
    content      = "${module.insecure_web_conf.user_data}"
  }

  part {
    filename     = "setup-hostname.cfg"
    content_type = "text/cloud-config"
    content      = "${module.setup_indexers_hostname.user_data}"
  }

  part {
    filename     = "license.cfg"
    content_type = "text/cloud-config"
    content      = "${module.slave_license_conf.user_data}"
  }

  part {
    filename     = "setup.cfg"
    content_type = "text/cloud-config"
    content      = "${module.splunk_setup.user_data}"
  }

  part {
    filename     = "custom.cfg"
    content_type = "text/cloud-config"
    content      = "${file(var.user_data_path)}"
  }
}

module "splunk_master" {
  source               = "../../modules/launch"
  instance_count       = 1
  ami_id               = "${module.amazon_ami.id}"
  instance_type        = "${var.instance_type}"
  key_pair_name        = "${local.ssh_key_pair_name}"
  tags                 = "${merge(local.tags, map("Name", "${var.env_name}-splunk-master"))}"
  iam_instance_profile = "${local.splunk_role_name}"

  eni_ids = [
    "${local.splunk_master_eni_id}",
  ]

  user_data = "${data.template_cloudinit_config.splunk_master_cloud_init_config.rendered}"
}

module "splunk_search_head" {
  source               = "../../modules/launch"
  instance_count       = 1
  ami_id               = "${module.amazon_ami.id}"
  instance_type        = "${var.instance_type}"
  key_pair_name        = "${local.ssh_key_pair_name}"
  tags                 = "${merge(local.tags, map("Name", "${var.env_name}-splunk-search-head"))}"
  iam_instance_profile = "${local.splunk_role_name}"

  eni_ids = [
    "${local.splunk_search_head_eni_id}",
  ]

  user_data = "${data.template_cloudinit_config.splunk_search_head_cloud_init_config.rendered}"
}

module "splunk_forwarders" {
  source               = "../../modules/launch"
  instance_count       = "${length(local.splunk_forwarders_eni_ids)}"
  ami_id               = "${module.amazon_ami.id}"
  instance_type        = "${var.instance_type}"
  key_pair_name        = "${local.ssh_key_pair_name}"
  tags                 = "${merge(local.tags, map("Name", "${var.env_name}-splunk-forwarder"))}"
  iam_instance_profile = "${local.splunk_role_name}"

  eni_ids = "${local.splunk_forwarders_eni_ids}"

  user_data = "${data.template_cloudinit_config.splunk_forwarders_cloud_init_config.rendered}"
}

module "splunk_indexers" {
  source               = "../../modules/launch"
  instance_count       = "${length(local.splunk_indexers_eni_ids)}"
  ami_id               = "${module.amazon_ami.id}"
  instance_type        = "${var.instance_type}"
  key_pair_name        = "${local.ssh_key_pair_name}"
  tags                 = "${merge(local.tags, map("Name", "${var.env_name}-splunk-indexer"))}"
  iam_instance_profile = "${local.splunk_role_name}"

  eni_ids = "${local.splunk_indexers_eni_ids}"

  user_data = "${data.template_cloudinit_config.splunk_indexers_cloud_init_config.rendered}"
}

resource "aws_volume_attachment" "splunk_master_volume_attachment" {
  skip_destroy = true

  instance_id = "${module.splunk_master.instance_ids[0]}"
  volume_id   = "${data.terraform_remote_state.bootstrap_splunk.master_data_volume}"
  device_name = "/dev/sdf"
}

resource "aws_volume_attachment" "splunk_search_head_volume_attachment" {
  skip_destroy = true

  instance_id = "${module.splunk_search_head.instance_ids[0]}"
  volume_id   = "${data.terraform_remote_state.bootstrap_splunk.search_head_data_volume}"
  device_name = "/dev/sdf"
}

resource "aws_volume_attachment" "splunk_indexers_volume_attachment" {
  skip_destroy = true

  count       = "${length(local.splunk_indexers_eni_ids)}"
  instance_id = "${module.splunk_indexers.instance_ids[count.index]}"
  volume_id   = "${element(data.terraform_remote_state.bootstrap_splunk.indexers_data_volumes, count.index)}"
  device_name = "/dev/sdf"
}

resource "aws_volume_attachment" "splunk_forwarders_volume_attachment" {
  skip_destroy = true

  count       = "${length(local.splunk_forwarders_eni_ids)}"
  instance_id = "${module.splunk_forwarders.instance_ids[count.index]}"
  volume_id   = "${element(data.terraform_remote_state.bootstrap_splunk.forwarders_data_volumes, count.index)}"
  device_name = "/dev/sdf"
}

resource "aws_elb_attachment" "splunk_master_attach" {
  elb      = "${data.terraform_remote_state.bootstrap_splunk.splunk_monitor_elb_id}"
  instance = "${module.splunk_master.instance_ids[0]}"
}

resource "aws_elb_attachment" "splunk_search_head_attach" {
  elb      = "${data.terraform_remote_state.bootstrap_splunk.splunk_search_head_elb_id}"
  instance = "${module.splunk_search_head.instance_ids[0]}"
}
