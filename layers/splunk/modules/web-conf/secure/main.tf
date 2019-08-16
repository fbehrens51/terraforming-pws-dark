variable "server_cert_content" {}
variable "server_key_content" {}
variable "web_port" {}
variable "mgmt_port" {}

data "template_file" "web_conf" {
  template = <<EOF
[settings]
httpport           = $${web_port}
mgmtHostPort       = 127.0.0.1:$${mgmt_port}

enableSplunkWebSSL = true
serverCert         = /opt/splunk/etc/auth/mycerts/mySplunkWebCertificate.pem
privKeyPath        = /opt/splunk/etc/auth/mycerts/mySplunkWebPrivateKey.key
EOF

  vars {
    mgmt_port = "${var.mgmt_port}"
    web_port  = "${var.web_port}"
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    web_conf_content    = "${data.template_file.web_conf.rendered}"
    server_cert_content = "${var.server_cert_content}"
    server_key_content  = "${var.server_key_content}"
  }
}

output "user_data" {
  value = "${data.template_file.user_data.rendered}"
}
