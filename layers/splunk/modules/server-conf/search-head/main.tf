variable "master_ip" {}
variable "mgmt_port" {}
variable "pass4SymmKey" {}
variable "splunk_syslog_ca_cert" {}

data "template_file" "search_head_server_conf" {
  template = <<EOF
[clustering]
mode = searchhead
master_uri = https://$${master_ip}:$${mgmt_port}
pass4SymmKey = $${pass4SymmKey}
EOF

  vars {
    master_ip    = "${var.master_ip}"
    mgmt_port    = "${var.mgmt_port}"
    pass4SymmKey = "${var.pass4SymmKey}"
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/../user_data.tpl")}"

  vars {
    server_conf_content = "${data.template_file.search_head_server_conf.rendered}"
    ca_cert_content     = "${var.splunk_syslog_ca_cert}"
  }
}

output "user_data" {
  value = "${data.template_file.user_data.rendered}"
}
