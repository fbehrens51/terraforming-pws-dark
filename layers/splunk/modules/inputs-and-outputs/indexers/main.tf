variable "input_port" {}

data "template_file" "inputs_conf" {
  template = <<EOF
[splunktcp://$${input_port}]
disabled = 0
EOF

  vars {
    input_port = "${var.input_port}"
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    inputs_conf_content = "${data.template_file.inputs_conf.rendered}"
  }
}

output "user_data" {
  value = "${data.template_file.user_data.rendered}"
}
