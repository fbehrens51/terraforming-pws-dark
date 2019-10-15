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

data "template_file" "server_conf" {
  template = <<EOF
[replication_port://${module.splunk_ports.splunk_replication_port}]

[clustering]
mode = slave
master_uri = https://${var.master_ip}:${module.splunk_ports.splunk_mgmt_port}
pass4SymmKey = ${var.indexers_pass4SymmKey}
EOF
}

data "template_file" "inputs_conf" {
  template = <<EOF
[splunktcp-ssl://${module.splunk_ports.splunk_tcp_port}]
disabled = 0

[SSL]
serverCert = /opt/splunk/etc/auth/mycerts/mySplunkServerCertificate.pem
EOF
}

data "template_file" "license_slave_server_conf" {
  template = <<EOF
[license]
master_uri = https://${var.master_ip}:${module.splunk_ports.splunk_mgmt_port}
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

- path: /tmp/server_cert.pem
  content: |
    ${indent(4, var.server_cert)}
    ${indent(4, var.server_key)}
    ${indent(4, var.ca_cert)}

- path: /tmp/inputs.conf
  content: |
    ${indent(4, data.template_file.inputs_conf.rendered)}

- path: /tmp/license.conf
  content: |
    ${indent(4, data.template_file.license_slave_server_conf.rendered)}

runcmd:
  - |
    set -ex

    mkdir -p /opt/splunk/etc/apps/SplunkLicenseSettings/local/
    mkdir -p /opt/splunk/etc/auth/mycerts
    mkdir -p /opt/splunk/etc/system/local/

    cp /tmp/inputs.conf /opt/splunk/etc/system/local/inputs.conf
    cp /tmp/license.conf /opt/splunk/etc/apps/SplunkLicenseSettings/local/server.conf
    cp /tmp/server.conf /opt/splunk/etc/system/local/server.conf
    cp /tmp/server_cert.pem /opt/splunk/etc/auth/mycerts/mySplunkServerCertificate.pem
    cp /tmp/splunk-ca.pem /opt/splunk/etc/auth/mycerts/mySplunkCACertificate.pem
EOF
}

data "template_cloudinit_config" "splunk_indexers_cloud_init_config" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "indexer.cfg"
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
  value = "${data.template_cloudinit_config.splunk_indexers_cloud_init_config.rendered}"
}
