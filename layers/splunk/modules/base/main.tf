variable "server_cert" {}
variable "server_key" {}
variable "ca_cert" {}
variable "user_data_path" {}
variable "root_domain" {}
variable "clamav_db_mirror" {}
variable "custom_clamav_yum_repo_url" {}
variable "splunk_password" {}
variable "splunk_rpm_version" {}
variable "splunk_rpm_s3_bucket" {}
variable "splunk_rpm_s3_region" {}
variable "role_name" {}

module "splunk_ports" {
  source = "../../../../modules/splunk_ports"
}

module "splunk_setup" {
  source = "../splunk-setup"

  admin_password       = "${var.splunk_password}"
  splunk_rpm_version   = "${var.splunk_rpm_version}"
  splunk_rpm_s3_bucket = "${var.splunk_rpm_s3_bucket}"
  splunk_rpm_s3_region = "${var.splunk_rpm_s3_region}"
}

module "syslog_config" {
  source                = "../../../../modules/syslog"
  root_domain           = "${var.root_domain}"
  splunk_syslog_ca_cert = "${var.ca_cert}"
}

module "clam_av_client_config" {
  source           = "../../../../modules/clamav/amzn2_systemd_client"
  clamav_db_mirror = "${var.clamav_db_mirror}"
  custom_repo_url  = "${var.custom_clamav_yum_repo_url}"
}

module "web_conf" {
  source = "../web-conf/secure"

  server_cert_content = "${var.server_cert}"
  server_key_content  = "${var.server_key}"
  web_port            = "${module.splunk_ports.splunk_web_port}"
  mgmt_port           = "${module.splunk_ports.splunk_mgmt_port}"
}

module "setup_hostname" {
  source = "../setup-hostname"
  role   = "${var.role_name}"
}

data "template_cloudinit_config" "splunk_master_cloud_init_config" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "syslog.cfg"
    content_type = "text/cloud-config"
    content      = "${module.syslog_config.user_data}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "webconf.cfg"
    content_type = "text/cloud-config"
    content      = "${module.web_conf.user_data}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "setup-hostname.cfg"
    content_type = "text/cloud-config"
    content      = "${module.setup_hostname.user_data}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "setup.cfg"
    content_type = "text/cloud-config"
    content      = "${module.splunk_setup.user_data}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "custom.cfg"
    content_type = "text/cloud-config"
    content      = "${file(var.user_data_path)}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "clamav.cfg"
    content_type = "text/cloud-config"
    content      = "${module.clam_av_client_config.client_user_data_config}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }
}

output "user_data" {
  value = "${data.template_cloudinit_config.splunk_master_cloud_init_config.rendered}"
}
