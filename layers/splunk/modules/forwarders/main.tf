variable "server_cert" {}
variable "server_key" {}
variable "ca_cert" {}
variable "forwarders_pass4SymmKey" {}
variable "user_accounts_user_data" {}
variable "root_domain" {}

variable "clamav_user_data" {}

variable "splunk_password" {}
variable "splunk_rpm_version" {}
variable "splunk_rpm_s3_bucket" {}
variable "splunk_rpm_s3_region" {}
variable "master_ip" {}
variable "splunk_http_collector_token" {}
variable "s3_archive_ip" {}
variable "s3_archive_port" {}
variable "public_bucket_name" {}
variable "public_bucket_url" {}
variable "banner_user_data" {}

module "base" {
  source      = "../base"
  server_cert = "${var.server_cert}"
  server_key  = "${var.server_key}"
  ca_cert     = "${var.ca_cert}"
  root_domain = "${var.root_domain}"

  clamav_user_data = "${var.clamav_user_data}"

  splunk_password         = "${var.splunk_password}"
  splunk_rpm_version      = "${var.splunk_rpm_version}"
  splunk_rpm_s3_bucket    = "${var.splunk_rpm_s3_bucket}"
  splunk_rpm_s3_region    = "${var.splunk_rpm_s3_region}"
  user_accounts_user_data = "${var.user_accounts_user_data}"
  role_name               = "splunk-forwarder"
  public_bucket_name      = "${var.public_bucket_name}"
  public_bucket_url       = "${var.public_bucket_url}"
  banner_user_data        = "${var.banner_user_data}"
}

module "splunk_ports" {
  source = "../../../../modules/splunk_ports"
}

data "template_file" "server_conf" {
  template = <<EOF
[applicationsManagement]
allowInternetAccess = false

[sslConfig]
serverCert = /opt/splunk/etc/auth/mycerts/mySplunkServerCertificate.pem
sslRootCAPath = /opt/splunk/etc/auth/mycerts/mySplunkCACertificate.pem
EOF
}

data "template_file" "inputs_conf" {
  template = <<EOF
[tcp-ssl://${module.splunk_ports.splunk_tcp_port}]
index = main
sourcetype = pcf
connection_host = dns

[SSL]
serverCert = /opt/splunk/etc/auth/mycerts/mySplunkServerCertificate.pem
EOF
}

data "template_file" "forwarder_app_conf" {
  template = <<EOF
[install]
state = enabled
EOF
}

data "template_file" "http_inputs_conf" {
  template = <<EOF

[http://PCF]
token = ${var.splunk_http_collector_token}
indexes = main, summary
index = main

[http]
disabled = 0
enableSSL = 1
port = ${module.splunk_ports.splunk_http_collector_port}
EOF
}

data "template_file" "outputs_conf" {
  template = <<EOF
[indexer_discovery:SplunkDiscovery]
pass4SymmKey = ${var.forwarders_pass4SymmKey}
master_uri = https://${var.master_ip}:${module.splunk_ports.splunk_mgmt_port}

[tcpout:s3Archive]
server = ${var.s3_archive_ip}:${var.s3_archive_port}
sendCookedData = false
maxQueueSeize = 25GB
useSSL = true

[tcpout:SplunkOutput]
indexerDiscovery = SplunkDiscovery
useSSL = true

[tcpout]
defaultGroup = SplunkOutput, s3Archive
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
- path: /run/server.conf
  content: |
    ${indent(4, data.template_file.server_conf.rendered)}

- path: /run/outputs.conf
  content: |
    ${indent(4, data.template_file.outputs_conf.rendered)}

- path: /run/http_inputs.conf
  content: |
    ${indent(4, data.template_file.http_inputs_conf.rendered)}

- path: /run/splunk_forwarder.conf
  content: |
    ${indent(4, data.template_file.forwarder_app_conf.rendered)}

- path: /run/inputs.conf
  content: |
    ${indent(4, data.template_file.inputs_conf.rendered)}

- path: /run/license.conf
  content: |
    ${indent(4, data.template_file.license_slave_server_conf.rendered)}

runcmd:
  - |
    set -ex

    mkdir -p /opt/splunk/etc/apps/SplunkForwarder/local/
    mkdir -p /opt/splunk/etc/apps/SplunkLicenseSettings/local/
    mkdir -p /opt/splunk/etc/apps/splunk_httpinput/local/
    mkdir -p /opt/splunk/etc/auth/mycerts
    mkdir -p /opt/splunk/etc/system/local/

    cp /run/http_inputs.conf /opt/splunk/etc/apps/splunk_httpinput/local/inputs.conf
    cp /run/inputs.conf /opt/splunk/etc/system/local/inputs.conf
    cp /run/license.conf /opt/splunk/etc/apps/SplunkLicenseSettings/local/server.conf
    cp /run/outputs.conf /opt/splunk/etc/system/local/outputs.conf
    cp /run/server.conf /opt/splunk/etc/system/local/server.conf
    cat /run/server.crt /run/server.key /run/splunk-ca.pem > /opt/splunk/etc/auth/mycerts/mySplunkServerCertificate.pem
    cp /run/splunk-ca.pem /opt/splunk/etc/auth/mycerts/mySplunkCACertificate.pem
    cp /run/splunk_forwarder.conf /opt/splunk/etc/apps/SplunkForwarder/local/app.conf
EOF
}

data "template_cloudinit_config" "user_data" {
  base64_encode = true
  gzip          = true

  part {
    filename     = "forwarder.cfg"
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
