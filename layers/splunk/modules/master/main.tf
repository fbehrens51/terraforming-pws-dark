variable "server_cert" {}
variable "server_key" {}
variable "ca_cert" {}
variable "indexers_pass4SymmKey" {}
variable "forwarders_pass4SymmKey" {}
variable "license_path" {}
variable "user_data_path" {}
variable "root_domain" {}
variable "clamav_db_mirror" {}
variable "custom_clamav_yum_repo_url" {}
variable "splunk_password" {}
variable "splunk_rpm_version" {}
variable "splunk_rpm_s3_bucket" {}
variable "splunk_rpm_s3_region" {}

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
  role_name                  = "splunk-master"
}

data "template_file" "server_conf" {
  template = <<EOF
[indexer_discovery]
pass4SymmKey = ${var.forwarders_pass4SymmKey}
indexerWeightByDiskCapacity = true

[clustering]
mode = master
replication_factor = 2
search_factor = 2
pass4SymmKey = ${var.indexers_pass4SymmKey}
EOF
}

data "template_file" "cloud_config" {
  template = <<EOF
#cloud-config
write_files:
- path: /tmp/server.conf
  content: |
    ${indent(4, data.template_file.server_conf.rendered)}

- path: /tmp/splunk-ca.pem
  content: |
    ${indent(4, var.ca_cert)}

- path: /tmp/license.lic
  content: |
    ${indent(4, file(var.license_path))}

runcmd:
  - |
    set -ex

    mkdir -p /opt/splunk/etc/auth/mycerts/
    mkdir -p /opt/splunk/etc/licenses/enterprise
    mkdir -p /opt/splunk/etc/system/local/

    cp /tmp/license.lic /opt/splunk/etc/licenses/enterprise/License.lic
    cp /tmp/server.conf /opt/splunk/etc/system/local/server.conf
    cp /tmp/splunk-ca.pem /opt/splunk/etc/auth/mycerts/mySplunkCACertificate.pem
EOF
}

data "template_cloudinit_config" "user_data" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "master.cfg"
    content_type = "text/cloud-config"
    content      = "${data.template_file.cloud_config.rendered}"
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
  value = "${data.template_cloudinit_config.user_data.rendered}"
}
