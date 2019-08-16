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

locals {
  splunk_master_eni_id      = "${data.terraform_remote_state.bootstrap_splunk.master_eni_ids[0]}"
  splunk_indexers_eni_ids   = "${data.terraform_remote_state.bootstrap_splunk.indexers_eni_ids}"
  splunk_forwarders_eni_ids = "${data.terraform_remote_state.bootstrap_splunk.forwarders_eni_ids}"
  splunk_search_head_eni_id = "${data.terraform_remote_state.bootstrap_splunk.search_head_eni_ids[0]}"

  splunk_http_collector_port = "${data.terraform_remote_state.bootstrap_splunk.splunk_http_collector_port}"
  splunk_mgmt_port           = "${data.terraform_remote_state.bootstrap_splunk.splunk_mgmt_port}"
  splunk_replication_port    = "${data.terraform_remote_state.bootstrap_splunk.splunk_replication_port}"
  splunk_tcp_port            = "${data.terraform_remote_state.bootstrap_splunk.splunk_tcp_port}"
  splunk_web_port            = "${data.terraform_remote_state.bootstrap_splunk.splunk_web_port}"

  tags = "${merge(var.tags, map("Name", "${var.env_name}-splunk"))}"

  splunk_role_name = "${data.terraform_remote_state.paperwork.splunk_role_name}"
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

module "amazon_ami" {
  source = "../../modules/amis/amazon_hvm_ami"
}

data "template_file" "indexers_server_conf" {
  template = <<EOF
[replication_port://$${replication_port}]

[clustering]
mode = slave
master_uri = https://$${master_ip}:$${mgmt_port}
pass4SymmKey = $${pass4SymmKey}
EOF

  vars {
    replication_port = "${local.splunk_replication_port}"
    master_ip        = "${data.terraform_remote_state.bootstrap_splunk.master_private_ips[0]}"
    mgmt_port        = "${local.splunk_mgmt_port}"
    pass4SymmKey     = "${data.terraform_remote_state.bootstrap_splunk.indexers_pass4SymmKey}"
  }
}

data "template_file" "outputs_conf" {
  template = <<EOF
[indexer_discovery:SplunkDiscovery]
pass4SymmKey = $${forwarders_pass4SymmKey}
master_uri = https://$${master_ip}:$${mgmt_port}

[tcpout:SplunkOutput]
indexerDiscovery = SplunkDiscovery

[tcpout]
defaultGroup = SplunkOutput
EOF

  vars {
    forwarders_pass4SymmKey = "${data.terraform_remote_state.bootstrap_splunk.forwarders_pass4SymmKey}"
    master_ip               = "${data.terraform_remote_state.bootstrap_splunk.master_private_ips[0]}"
    mgmt_port               = "${local.splunk_mgmt_port}"
  }
}

data "template_file" "forwarders_http_inputs_conf" {
  template = <<EOF

[http://PCF]
token = $${http_token}
indexes = main, summary
index = main

[http]
disabled = 0
enableSSL = 1
port = $${http_collector_port}
EOF

  vars {
    http_token          = "${data.terraform_remote_state.bootstrap_splunk.splunk_http_collector_token}"
    http_collector_port = "${local.splunk_http_collector_port}"
  }
}

data "template_file" "forwarders_syslog_inputs_conf" {
  template = <<EOF
[tcp://$${tcp_port}]
index = main
sourcetype = pcf
connection_host = dns
EOF

  vars {
    tcp_port = "${local.splunk_tcp_port}"
  }
}

data "template_file" "indexer_inputs_conf" {
  template = <<EOF
[splunktcp://$${tcp_port}]
disabled = 0
EOF

  vars {
    tcp_port = "${local.splunk_tcp_port}"
  }
}

data "template_file" "master_server_conf" {
  template = <<EOF
[indexer_discovery]
pass4SymmKey = $${forwarders_pass4SymmKey}
indexerWeightByDiskCapacity = true

[clustering]
mode = master
replication_factor = $${replication_factor}
search_factor = $${search_factor}
pass4SymmKey = $${indexers_pass4SymmKey}
EOF

  vars {
    replication_factor      = "2"
    search_factor           = "2"
    indexers_pass4SymmKey   = "${data.terraform_remote_state.bootstrap_splunk.indexers_pass4SymmKey}"
    forwarders_pass4SymmKey = "${data.terraform_remote_state.bootstrap_splunk.forwarders_pass4SymmKey}"
  }
}

data "template_file" "search_head_server_conf" {
  template = <<EOF
[clustering]
mode = searchhead
master_uri = https://$${master_ip}:$${mgmt_port}
pass4SymmKey = $${pass4SymmKey}
EOF

  vars {
    master_ip    = "${data.terraform_remote_state.bootstrap_splunk.master_private_ips[0]}"
    mgmt_port    = "${local.splunk_mgmt_port}"
    pass4SymmKey = "${data.terraform_remote_state.bootstrap_splunk.indexers_pass4SymmKey}"
  }
}

data "template_file" "secure_web_conf" {
  template = <<EOF
[settings]
httpport           = $${web_port}
mgmtHostPort       = 127.0.0.1:$${mgmt_port}

enableSplunkWebSSL = true
serverCert         = /opt/splunk/etc/auth/mycerts/mySplunkWebCertificate.pem
privKeyPath        = /opt/splunk/etc/auth/mycerts/mySplunkWebPrivateKey.key
EOF

  vars {
    mgmt_port = "${local.splunk_mgmt_port}"
    web_port  = "${local.splunk_web_port}"
  }
}

data "template_file" "web_conf" {
  template = <<EOF
[settings]
httpport        = $${web_port}
mgmtHostPort    = 127.0.0.1:$${mgmt_port}
EOF

  vars {
    mgmt_port = "${local.splunk_mgmt_port}"
    web_port  = "${local.splunk_web_port}"
  }
}

data "template_file" "splunk_forwarder_app_conf" {
  template = <<EOF
[install]
state = enabled
EOF

  vars {}
}

data "template_file" "master_user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    password                  = "${data.terraform_remote_state.bootstrap_splunk.splunk_password}"
    server_conf_content       = "${data.template_file.master_server_conf.rendered}"
    web_conf_content          = "${data.template_file.secure_web_conf.rendered}"
    inputs_conf_content       = "${data.template_file.indexer_inputs_conf.rendered}"
    splunk_forwarder_app_conf = ""
    outputs_conf_content      = ""
    http_inputs_conf_content  = ""
    role                      = "splunk-master"
    server_cert_content       = "${data.terraform_remote_state.paperwork.splunk_monitor_server_cert}"
    server_key_content        = "${data.terraform_remote_state.paperwork.splunk_monitor_server_key}"
    splunk_rpm_version        = "${var.splunk_rpm_version}"
    splunk_rpm_s3_bucket      = "${var.splunk_rpm_s3_bucket}"
    splunk_rpm_s3_region      = "${var.splunk_rpm_s3_region}"
  }
}

data "template_file" "search_head_user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    password                  = "${data.terraform_remote_state.bootstrap_splunk.splunk_password}"
    server_conf_content       = "${data.template_file.search_head_server_conf.rendered}"
    web_conf_content          = "${data.template_file.secure_web_conf.rendered}"
    inputs_conf_content       = ""
    splunk_forwarder_app_conf = ""
    outputs_conf_content      = ""
    http_inputs_conf_content  = ""
    role                      = "splunk-search-head"
    server_cert_content       = "${data.terraform_remote_state.paperwork.splunk_server_cert}"
    server_key_content        = "${data.terraform_remote_state.paperwork.splunk_server_key}"
    splunk_rpm_version        = "${var.splunk_rpm_version}"
    splunk_rpm_s3_bucket      = "${var.splunk_rpm_s3_bucket}"
    splunk_rpm_s3_region      = "${var.splunk_rpm_s3_region}"
  }
}

data "template_file" "forwarders_user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    password                  = "${data.terraform_remote_state.bootstrap_splunk.splunk_password}"
    server_conf_content       = ""
    web_conf_content          = "${data.template_file.web_conf.rendered}"
    inputs_conf_content       = "${data.template_file.forwarders_syslog_inputs_conf.rendered}"
    splunk_forwarder_app_conf = "${data.template_file.splunk_forwarder_app_conf.rendered}"
    outputs_conf_content      = "${data.template_file.outputs_conf.rendered}"
    http_inputs_conf_content  = "${data.template_file.forwarders_http_inputs_conf.rendered}"
    role                      = "splunk-forwarder"
    server_cert_content       = ""
    server_key_content        = ""
    splunk_rpm_version        = "${var.splunk_rpm_version}"
    splunk_rpm_s3_bucket      = "${var.splunk_rpm_s3_bucket}"
    splunk_rpm_s3_region      = "${var.splunk_rpm_s3_region}"
  }
}

data "template_file" "indexers_user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    password                  = "${data.terraform_remote_state.bootstrap_splunk.splunk_password}"
    server_conf_content       = "${data.template_file.indexers_server_conf.rendered}"
    web_conf_content          = "${data.template_file.web_conf.rendered}"
    inputs_conf_content       = "${data.template_file.indexer_inputs_conf.rendered}"
    splunk_forwarder_app_conf = ""
    outputs_conf_content      = ""
    http_inputs_conf_content  = ""
    role                      = "splunk-indexer"
    server_cert_content       = ""
    server_key_content        = ""
    splunk_rpm_version        = "${var.splunk_rpm_version}"
    splunk_rpm_s3_bucket      = "${var.splunk_rpm_s3_bucket}"
    splunk_rpm_s3_region      = "${var.splunk_rpm_s3_region}"
  }
}

data "template_cloudinit_config" "splunk_master_cloud_init_config" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "install.cfg"
    content_type = "text/cloud-config"
    content      = "${data.template_file.master_user_data.rendered}"
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
    filename     = "install.cfg"
    content_type = "text/cloud-config"
    content      = "${data.template_file.search_head_user_data.rendered}"
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
    filename     = "install.cfg"
    content_type = "text/cloud-config"
    content      = "${data.template_file.forwarders_user_data.rendered}"
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
    filename     = "install.cfg"
    content_type = "text/cloud-config"
    content      = "${data.template_file.indexers_user_data.rendered}"
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
  key_pair_name        = "${data.terraform_remote_state.bootstrap_splunk.splunk_ssh_key_pair_name}"
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
  key_pair_name        = "${data.terraform_remote_state.bootstrap_splunk.splunk_ssh_key_pair_name}"
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
  key_pair_name        = "${data.terraform_remote_state.bootstrap_splunk.splunk_ssh_key_pair_name}"
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
  key_pair_name        = "${data.terraform_remote_state.bootstrap_splunk.splunk_ssh_key_pair_name}"
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
