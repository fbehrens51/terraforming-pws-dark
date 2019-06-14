variable "client_cidr" {}

variable "zone_name" {}

variable "master_ip" {}

locals {
  last_master_octet = "${element(split(".",var.master_ip),3)}"

  reverse_name = "${format("%s.%s.%s",
      element(split(".", var.master_ip), 2),
      element(split(".", var.master_ip), 1),
      element(split(".", var.master_ip), 0)
      )
  }"
}

data "template_file" "named_conf_content" {
  template = "${file("${path.module}/named.conf.tpl")}"

  vars {
    client_cidr         = "${var.client_cidr}"
    zone_name           = "${var.zone_name}"
    master_ip           = "${var.master_ip}"
    reverse_cidr_prefix = "${local.reverse_name}"
  }
}

output "named_conf_content" {
  value = "${data.template_file.named_conf_content.rendered}"
}
