variable "master_ip" {}
variable "mgmt_port" {}
variable "http_token" {}
variable "syslog_port" {}
variable "http_collector_port" {}
variable "pass4SymmKey" {}

data "template_file" "outputs_conf" {
  template = <<EOF
[indexer_discovery:SplunkDiscovery]
pass4SymmKey = $${pass4SymmKey}
master_uri = https://$${master_ip}:$${mgmt_port}

[tcpout:SplunkOutput]
indexerDiscovery = SplunkDiscovery

[tcpout]
defaultGroup = SplunkOutput
EOF

  vars {
    pass4SymmKey = "${var.pass4SymmKey}"
    master_ip    = "${var.master_ip}"
    mgmt_port    = "${var.mgmt_port}"
  }
}

data "template_file" "http_inputs_conf" {
  template = <<EOF

[http://PCF]
token = $${http_token}
indexes = main, summary
index = main

[http]
disabled = 0
enableSSL = 1
port = $${http_collector_port}
EOF

  vars {
    http_token          = "${var.http_token}"
    http_collector_port = "${var.http_collector_port}"
  }
}

data "template_file" "forwarder_app_conf" {
  template = <<EOF
[install]
state = enabled
EOF
}

data "template_file" "syslog_inputs_conf" {
  template = <<EOF
[tcp://$${syslog_port}]
index = main
sourcetype = pcf
connection_host = dns
EOF

  vars {
    syslog_port = "${var.syslog_port}"
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    inputs_conf_content       = "${data.template_file.syslog_inputs_conf.rendered}"
    splunk_forwarder_app_conf = "${data.template_file.forwarder_app_conf.rendered}"
    outputs_conf_content      = "${data.template_file.outputs_conf.rendered}"
    http_inputs_conf_content  = "${data.template_file.http_inputs_conf.rendered}"
  }
}

output "user_data" {
  value = "${data.template_file.user_data.rendered}"
}
