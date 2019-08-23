variable "license_path" {}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    license_path = "${var.license_path}"
  }
}

output "user_data" {
  value = "${data.template_file.user_data.rendered}"
}
