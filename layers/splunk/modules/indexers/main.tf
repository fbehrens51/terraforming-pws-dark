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

variable "search_heads_pass4SymmKey" {
}

variable "clamav_user_data" {
}

variable "splunk_password" {
}

variable "splunk_rpm_version" {
}

variable "transfer_bucket_name" {
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
  source           = "../base"
  server_cert      = var.server_cert
  server_key       = var.server_key
  ca_cert          = var.ca_cert
  root_domain      = var.root_domain
  clamav_user_data = var.clamav_user_data

  splunk_password = var.splunk_password

  splunk_rpm_version      = var.splunk_rpm_version
  transfer_bucket_name    = var.transfer_bucket_name
  region                  = var.region
  user_accounts_user_data = var.user_accounts_user_data
  role_name               = "splunk-indexer"
  public_bucket_name      = var.public_bucket_name
  public_bucket_url       = var.public_bucket_url
  banner_user_data        = var.banner_user_data
  instance_user_data      = data.template_file.cloud_config.rendered
}

module "splunk_ports" {
  source = "../../../../modules/splunk_ports"
}

data "template_file" "server_conf" {
  template = <<EOF
[sslConfig]
serverCert = /opt/splunk/etc/auth/mycerts/mySplunkServerCertificate.pem
sslRootCAPath = /opt/splunk/etc/auth/mycerts/mySplunkCACertificate.pem

[replication_port-ssl://${module.splunk_ports.splunk_replication_port}]
serverCert = /opt/splunk/etc/auth/mycerts/mySplunkServerCertificate.pem

[applicationsManagement]
allowInternetAccess = false

[shclustering]
pass4SymmKey = ${var.search_heads_pass4SymmKey}

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
- path: /run/server.conf
  content: |
    ${indent(4, data.template_file.server_conf.rendered)}

- path: /run/inputs.conf
  content: |
    ${indent(4, data.template_file.inputs_conf.rendered)}

- path: /run/license.conf
  content: |
    ${indent(4, data.template_file.license_slave_server_conf.rendered)}

runcmd:
  - |
    set -ex

    mkdir -p /opt/splunk/etc/apps/SplunkLicenseSettings/local/
    mkdir -p /opt/splunk/etc/auth/mycerts
    mkdir -p /opt/splunk/etc/system/local/

    cp /run/inputs.conf /opt/splunk/etc/system/local/inputs.conf
    cp /run/license.conf /opt/splunk/etc/apps/SplunkLicenseSettings/local/server.conf
    cp /run/server.conf /opt/splunk/etc/system/local/server.conf
    cat /run/server.crt /run/server.key /run/splunk-ca.pem > /opt/splunk/etc/auth/mycerts/mySplunkServerCertificate.pem
    cp /run/splunk-ca.pem /opt/splunk/etc/auth/mycerts/mySplunkCACertificate.pem
EOF

}

output "user_data" {
  value = module.base.user_data
}

