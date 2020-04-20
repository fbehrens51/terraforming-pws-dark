variable "server_cert" {
}

variable "server_key" {
}

variable "ca_cert" {
}

variable "user_accounts_user_data" {
}

variable "root_domain" {
}

variable "indexers_pass4SymmKey" {
}

variable "forwarders_pass4SymmKey" {
}

variable "search_heads_pass4SymmKey" {
}

variable "clamav_user_data" {
}

variable "node_exporter_user_data" {
}

variable "splunk_password" {
}

variable "splunk_rpm_version" {
}

variable "region" {
}

variable "master_ip" {
}

variable "public_bucket_name" {
}

variable "public_bucket_url" {
}

variable "banner_user_data" {
}

module "base" {
  source      = "../base"
  server_cert = var.server_cert
  server_key  = var.server_key
  ca_cert     = var.ca_cert
  root_domain = var.root_domain

  clamav_user_data        = var.clamav_user_data
  node_exporter_user_data = var.node_exporter_user_data

  splunk_password         = var.splunk_password
  splunk_rpm_version      = var.splunk_rpm_version
  region                  = var.region
  user_accounts_user_data = var.user_accounts_user_data
  role_name               = "splunk-search-head"
  public_bucket_name      = var.public_bucket_name
  public_bucket_url       = var.public_bucket_url
  banner_user_data        = var.banner_user_data
  instance_user_data      = data.template_file.cloud_config.rendered
}

module "splunk_ports" {
  source = "../../../../modules/splunk_ports"
}

data "template_file" "license_slave_server_conf" {
  template = <<EOF
[license]
master_uri = https://${var.master_ip}:${module.splunk_ports.splunk_mgmt_port}
EOF

}

data "template_file" "server_conf" {
  template = <<EOF
[sslConfig]
serverCert = /opt/splunk/etc/auth/mycerts/mySplunkServerCertificate.pem
sslRootCAPath = /opt/splunk/etc/auth/mycerts/mySplunkCACertificate.pem
sslVersions = tls1.2
sslVersionsForClient = tls1.2
cipherSuite = ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-
SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-
AES128-SHA256:ECDHE-RSA-AES128-SHA256:AES256-GCM-SHA384:AES128-GCM-SHA256:AES128-SHA256
ecdhCurves = prime256v1, secp384r1, secp521r1
sendStrictTransportSecurityHeader = true

[applicationsManagement]
allowInternetAccess = false
sslVersions = tls1.2
cipherSuite = ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-
SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-
AES128-SHA256:ECDHE-RSA-AES128-SHA256
ecdhCurves = prime256v1, secp384r1, secp521r1

[shclustering]
pass4SymmKey = ${var.search_heads_pass4SymmKey}

[clustering]
mode = searchhead
master_uri = https://${var.master_ip}:${module.splunk_ports.splunk_mgmt_port}
pass4SymmKey = ${var.indexers_pass4SymmKey}

[default]
sendStrictTransportSecurityHeader = true
EOF

}

data "template_file" "outputs_conf" {
  template = <<EOF
[indexAndForward]
index = false

[indexer_discovery:SplunkDiscovery]
pass4SymmKey = ${var.forwarders_pass4SymmKey}
master_uri = https://${var.master_ip}:${module.splunk_ports.splunk_mgmt_port}

[tcpout:SplunkOutput]
indexerDiscovery = SplunkDiscovery
useSSL = true

[tcpout]
defaultGroup = SplunkOutput
forwardedindex.filter.disable = true
indexAndForward = false
sslVersions = tls1.2
cipherSuite = ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-
SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-
AES128-SHA256:ECDHE-RSA-AES128-SHA256
ecdhCurves = prime256v1, secp384r1, secp521r1
EOF

}

data "template_file" "cloud_config" {
  template = <<EOF
#cloud-config
write_files:
- path: /run/server.conf
  content: |
    ${indent(4, data.template_file.server_conf.rendered)}

- path: /run/license.conf
  content: |
    ${indent(4, data.template_file.license_slave_server_conf.rendered)}

- path: /run/outputs.conf
  content: |
    ${indent(4, data.template_file.outputs_conf.rendered)}

runcmd:
  - |
    set -ex

    mkdir -p /opt/splunk/etc/apps/SplunkLicenseSettings/local/
    mkdir -p /opt/splunk/etc/auth/mycerts/
    mkdir -p /opt/splunk/etc/system/local/

    cp /run/license.conf /opt/splunk/etc/apps/SplunkLicenseSettings/local/server.conf
    cp /run/server.conf /opt/splunk/etc/system/local/server.conf
    cat /run/server.crt /run/server.key /run/splunk-ca.pem > /opt/splunk/etc/auth/mycerts/mySplunkServerCertificate.pem
    cp /run/outputs.conf /opt/splunk/etc/system/local/outputs.conf
    cp /run/splunk-ca.pem /opt/splunk/etc/auth/mycerts/mySplunkCACertificate.pem
EOF

}

output "user_data" {
  value = module.base.user_data
}

