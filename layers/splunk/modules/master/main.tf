variable "server_cert" {}
variable "server_key" {}
variable "ca_cert" {}
variable "indexers_pass4SymmKey" {}
variable "forwarders_pass4SymmKey" {}
variable "search_heads_pass4SymmKey" {}
variable "license_path" {}
variable "user_accounts_user_data" {}
variable "root_domain" {}

variable "clamav_user_data" {}

variable "splunk_password" {}
variable "splunk_rpm_version" {}
variable "transfer_bucket_name" {}
variable "region" {}
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
  transfer_bucket_name    = "${var.transfer_bucket_name}"
  region    = "${var.region}"
  user_accounts_user_data = "${var.user_accounts_user_data}"

  role_name          = "splunk-master"
  public_bucket_name = "${var.public_bucket_name}"
  public_bucket_url  = "${var.public_bucket_url}"
  banner_user_data   = "${var.banner_user_data}"
}

data "template_file" "server_conf" {
  template = <<EOF
[sslConfig]
serverCert = /opt/splunk/etc/auth/mycerts/mySplunkServerCertificate.pem
sslRootCAPath = /opt/splunk/etc/auth/mycerts/mySplunkCACertificate.pem

[indexer_discovery]
pass4SymmKey = ${var.forwarders_pass4SymmKey}
indexerWeightByDiskCapacity = true

[applicationsManagement]
allowInternetAccess = false

[shclustering]
pass4SymmKey = ${var.search_heads_pass4SymmKey}

[clustering]
mode = master
replication_factor = 2
search_factor = 2
pass4SymmKey = ${var.indexers_pass4SymmKey}
EOF
}

module "splunk_ports" {
  source = "../../../../modules/splunk_ports"
}

data "template_file" "outputs_conf" {
  template = <<EOF
[indexAndForward]
index = false

[indexer_discovery:SplunkDiscovery]
pass4SymmKey = ${var.forwarders_pass4SymmKey}
master_uri = https://localhost:${module.splunk_ports.splunk_mgmt_port}

[tcpout:SplunkOutput]
indexerDiscovery = SplunkDiscovery
useSSL = true

[tcpout]
defaultGroup = SplunkOutput
forwardedindex.filter.disable = true
indexAndForward = false
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

- path: /run/splunk-ca.pem
  content: |
    ${indent(4, var.ca_cert)}

- path: /run/license.lic
  content: |
    ${indent(4, file(var.license_path))}

runcmd:
  - |
    set -ex

    mkdir -p /opt/splunk/etc/auth/mycerts/
    mkdir -p /opt/splunk/etc/licenses/enterprise
    mkdir -p /opt/splunk/etc/system/local/

    cp /run/license.lic /opt/splunk/etc/licenses/enterprise/License.lic
    cp /run/server.conf /opt/splunk/etc/system/local/server.conf
    cp /run/outputs.conf /opt/splunk/etc/system/local/outputs.conf
    cat /run/server.crt /run/server.key /run/splunk-ca.pem > /opt/splunk/etc/auth/mycerts/mySplunkServerCertificate.pem
    cp /run/splunk-ca.pem /opt/splunk/etc/auth/mycerts/mySplunkCACertificate.pem
EOF
}

data "template_cloudinit_config" "user_data" {
  base64_encode = true
  gzip          = true

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
