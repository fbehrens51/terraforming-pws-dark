variable "client_cidr" {}

variable "zone_name" {}

variable "master_ip" {}

module "bind_conf_content" {
  source      = "../conf"
  client_cidr = "${var.client_cidr}"
  master_ip   = "${var.master_ip}"
  zone_name   = "${var.zone_name}"
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    named_conf_content = "${base64encode(module.bind_conf_content.named_conf_content)}"
  }
}

output "user_data" {
  value = "${data.template_file.user_data.rendered}"
}
