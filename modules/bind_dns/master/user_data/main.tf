variable "client_cidr" {}

variable "slave_ips" {
  type = "list"
}

variable "zone_name" {}

variable "master_ip" {}

variable "secret" {}

module "bind_conf_content" {
  source      = "../conf"
  client_cidr = "${var.client_cidr}"
  master_ip   = "${var.master_ip}"
  secret      = "${var.secret}"
  slave_ips   = "${var.slave_ips}"
  zone_name   = "${var.zone_name}"
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    named_conf_content = "${base64encode(module.bind_conf_content.named_conf_content)}"
    zone_content       = "${base64encode(module.bind_conf_content.zone_content)}"
    zone_file_name     = "db.${var.zone_name}"
    reverse_content    = "${base64encode(module.bind_conf_content.reverse_content)}"
    rndc_content       = "${base64encode(module.bind_conf_content.rndc_key_content)}"
    reverse_file_name  = "db.${module.bind_conf_content.reverse_name}"
  }
}

data "template_cloudinit_config" "master_bind_conf_userdata" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "master_bind_conf.cfg"
    content_type = "text/cloud-config"
    content      = "${data.template_file.user_data.rendered}"
  }
}

output "user_data" {
  value     = "${data.template_cloudinit_config.master_bind_conf_userdata.rendered}"
  sensitive = true
}
