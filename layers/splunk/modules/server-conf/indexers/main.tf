variable "master_ip" {}
variable "mgmt_port" {}
variable "pass4SymmKey" {}
variable "replication_port" {}

data "template_file" "indexers_server_conf" {
  template = <<EOF
[replication_port://$${replication_port}]

[clustering]
mode = slave
master_uri = https://$${master_ip}:$${mgmt_port}
pass4SymmKey = $${pass4SymmKey}
EOF

  vars {
    replication_port = "${var.replication_port}"
    master_ip        = "${var.master_ip}"
    mgmt_port        = "${var.mgmt_port}"
    pass4SymmKey     = "${var.pass4SymmKey}"
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/../user_data.tpl")}"

  vars {
    server_conf_content = "${data.template_file.indexers_server_conf.rendered}"
  }
}

output "user_data" {
  value = "${data.template_file.user_data.rendered}"
}
