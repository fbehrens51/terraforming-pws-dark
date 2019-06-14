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

data "template_cloudinit_config" "slave_bind_conf_userdata" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "slave_bind_conf.cfg"
    content_type = "text/cloud-config"
    content      = "${data.template_file.user_data.rendered}"
  }
}

output "user_data" {
  value = "${data.template_cloudinit_config.slave_bind_conf_userdata.rendered}"
}
