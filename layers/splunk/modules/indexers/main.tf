variable "server_cert" {}
variable "server_key" {}
variable "ca_cert" {}
variable "indexers_pass4SymmKey" {}
variable "user_data_path" {}
variable "root_domain" {}
variable "clamav_db_mirror" {}
variable "custom_clamav_yum_repo_url" {}
variable "splunk_password" {}
variable "splunk_rpm_version" {}
variable "splunk_rpm_s3_bucket" {}
variable "splunk_rpm_s3_region" {}
variable "master_ip" {}

module "base" {
  source                     = "../base"
  server_cert                = "${var.server_cert}"
  server_key                 = "${var.server_key}"
  ca_cert                    = "${var.ca_cert}"
  root_domain                = "${var.root_domain}"
  clamav_db_mirror           = "${var.clamav_db_mirror}"
  custom_clamav_yum_repo_url = "${var.custom_clamav_yum_repo_url}"
  splunk_password            = "${var.splunk_password}"
  splunk_rpm_version         = "${var.splunk_rpm_version}"
  splunk_rpm_s3_bucket       = "${var.splunk_rpm_s3_bucket}"
  splunk_rpm_s3_region       = "${var.splunk_rpm_s3_region}"
  user_data_path             = "${var.user_data_path}"
  role_name                  = "splunk-indexer"
}

module "splunk_ports" {
  source = "../../../../modules/splunk_ports"
}

module "indexers_server_conf" {
  source = "../server-conf/indexers"

  master_ip             = "${var.master_ip}"
  mgmt_port             = "${module.splunk_ports.splunk_mgmt_port}"
  pass4SymmKey          = "${var.indexers_pass4SymmKey}"
  replication_port      = "${module.splunk_ports.splunk_replication_port}"
  splunk_syslog_ca_cert = "${var.ca_cert}"
}

module "indexers_inputs_conf" {
  source      = "../inputs-and-outputs/indexers"
  input_port  = "${module.splunk_ports.splunk_tcp_port}"
  server_cert = "${var.server_cert}"
  server_key  = "${var.server_key}"
  ca_cert     = "${var.ca_cert}"
}

module "slave_license_conf" {
  source = "../license-conf/slave"

  master_ip = "${var.master_ip}"
  mgmt_port = "${module.splunk_ports.splunk_mgmt_port}"
}

data "template_cloudinit_config" "splunk_indexers_cloud_init_config" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "serverconf.cfg"
    content_type = "text/cloud-config"
    content      = "${module.indexers_server_conf.user_data}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "inputsconf.cfg"
    content_type = "text/cloud-config"
    content      = "${module.indexers_inputs_conf.user_data}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "license.cfg"
    content_type = "text/cloud-config"
    content      = "${module.slave_license_conf.user_data}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "base.cfg"
    content_type = "text/cloud-config"
    content      = "${module.base.user_data}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }
}

output "user_data" {
  value = "${data.template_cloudinit_config.splunk_indexers_cloud_init_config.rendered}"
}
