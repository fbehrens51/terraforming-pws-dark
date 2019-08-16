variable "role" {}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    role = "${var.role}"
  }
}

output "user_data" {
  value = "${data.template_file.user_data.rendered}"
}
