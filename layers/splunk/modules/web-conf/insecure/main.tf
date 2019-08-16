variable "web_port" {}
variable "mgmt_port" {}

data "template_file" "web_conf" {
  template = <<EOF
[settings]
httpport        = $${web_port}
mgmtHostPort    = 127.0.0.1:$${mgmt_port}
EOF

  vars {
    mgmt_port = "${var.mgmt_port}"
    web_port  = "${var.web_port}"
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    web_conf_content = "${data.template_file.web_conf.rendered}"
  }
}

output "user_data" {
  value = "${data.template_file.user_data.rendered}"
}
