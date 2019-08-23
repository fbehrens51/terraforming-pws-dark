variable "master_ip" {}
variable "mgmt_port" {}

data "template_file" "license_slave_server_conf" {
  template = <<EOF
[license]
master_uri = https://$${master_ip}:$${mgmt_port}
EOF

  vars {
    master_ip = "${var.master_ip}"
    mgmt_port = "${var.mgmt_port}"
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    license_conf_content = "${data.template_file.license_slave_server_conf.rendered}"
  }
}

output "user_data" {
  value = "${data.template_file.user_data.rendered}"
}
