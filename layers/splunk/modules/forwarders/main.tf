variable "server_cert" {}
variable "server_key" {}
variable "ca_cert" {}
variable "forwarders_pass4SymmKey" {}
variable "user_data_path" {}
variable "root_domain" {}
variable "clamav_db_mirror" {}
variable "custom_clamav_yum_repo_url" {}
variable "splunk_password" {}
variable "splunk_rpm_version" {}
variable "splunk_rpm_s3_bucket" {}
variable "splunk_rpm_s3_region" {}
variable "master_ip" {}
variable "splunk_http_collector_token" {}
variable "s3_archive_ip" {}
variable "s3_archive_port" {}

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
  role_name                  = "splunk-forwarder"
}

module "splunk_ports" {
  source = "../../../../modules/splunk_ports"
}

module "slave_license_conf" {
  source = "../license-conf/slave"

  master_ip = "${var.master_ip}"
  mgmt_port = "${module.splunk_ports.splunk_mgmt_port}"
}

module "forwarders_server_conf" {
  source                = "../server-conf/forwarders"
  splunk_syslog_ca_cert = "${var.ca_cert}"
}

module "forwarders_inputs_outputs_conf" {
  source = "../inputs-and-outputs/forwarders"

  syslog_port         = "${module.splunk_ports.splunk_tcp_port}"
  master_ip           = "${var.master_ip}"
  mgmt_port           = "${module.splunk_ports.splunk_mgmt_port}"
  http_token          = "${var.splunk_http_collector_token}"
  http_collector_port = "${module.splunk_ports.splunk_http_collector_port}"
  pass4SymmKey        = "${var.forwarders_pass4SymmKey}"
  s3_archive_ip       = "${var.s3_archive_ip}"
  s3_archive_port     = "${var.s3_archive_port}"
  server_cert         = "${var.server_cert}"
  server_key          = "${var.server_key}"
  ca_cert             = "${var.ca_cert}"
}

data "template_cloudinit_config" "splunk_forwarders_cloud_init_config" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "inputsconf.cfg"
    content_type = "text/cloud-config"
    content      = "${module.forwarders_inputs_outputs_conf.user_data}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "server-conf.cfg"
    content_type = "text/cloud-config"
    content      = "${module.forwarders_server_conf.user_data}"
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
  value = "${data.template_cloudinit_config.splunk_forwarders_cloud_init_config.rendered}"
}
