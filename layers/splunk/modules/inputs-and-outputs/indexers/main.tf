variable "input_port" {}
variable "ca_cert" {}
variable "server_cert" {}
variable "server_key" {}

data "template_file" "inputs_conf" {
  template = <<EOF
[splunktcp-ssl://$${input_port}]
disabled = 0

[SSL]
serverCert = /opt/splunk/etc/auth/mycerts/mySplunkServerCertificate.pem
EOF

  vars {
    input_port = "${var.input_port}"
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    inputs_conf_content = "${data.template_file.inputs_conf.rendered}"
    server_cert         = "${var.server_cert}"
    server_key          = "${var.server_key}"
    ca_cert             = "${var.ca_cert}"
  }
}

output "user_data" {
  value = "${data.template_file.user_data.rendered}"
}
