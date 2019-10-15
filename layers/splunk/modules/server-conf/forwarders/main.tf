variable "splunk_syslog_ca_cert" {}

data "template_file" "indexers_server_conf" {
  template = <<EOF
[sslConfig]
serverCert = /opt/splunk/etc/auth/mycerts/mySplunkServerCertificate.pem
sslRootCAPath = /opt/splunk/etc/auth/mycerts/mySplunkCACertificate.pem
EOF
}

data "template_file" "user_data" {
  template = "${file("${path.module}/../user_data.tpl")}"

  vars {
    server_conf_content = "${data.template_file.indexers_server_conf.rendered}"
    ca_cert_content     = "${var.splunk_syslog_ca_cert}"
  }
}

output "user_data" {
  value = "${data.template_file.user_data.rendered}"
}
