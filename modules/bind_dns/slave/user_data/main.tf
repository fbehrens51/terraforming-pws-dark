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

variable "clamav_db_mirror" {}

module "clam_av_client_config" {
  source           = "../../../clamav/amzn2_systemd_client"
  clamav_db_mirror = "${var.clamav_db_mirror}"
}

module "syslog_config" {
  source      = "../../../syslog"
  root_domain = "${var.zone_name}"
}

data "template_cloudinit_config" "slave_bind_conf_userdata" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "syslog.cfg"
    content_type = "text/cloud-config"
    content      = "${module.syslog_config.user_data}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "slave_bind_conf.cfg"
    content_type = "text/cloud-config"
    content      = "${data.template_file.user_data.rendered}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "clamav.cfg"
    content_type = "text/cloud-config"
    content      = "${module.clam_av_client_config.client_user_data_config}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }
}

output "user_data" {
  value = "${data.template_cloudinit_config.slave_bind_conf_userdata.rendered}"
}
