variable "clamav_db_mirror" {}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    clam_database_mirror = "${var.clamav_db_mirror}"
    aug_lens = "${indent(8,file("${path.module}/clamav.aug"))}"
    service_file = "${indent(8,file("${path.module}/freshclam.service"))}"
  }
}

data "template_cloudinit_config" "cloud_config" {
  base64_encode = false
  gzip          = false

  part {
    content = "${data.template_file.user_data.rendered}"
  }
}

output "client_user_data_config" {
  value = "${data.template_file.user_data.rendered}"
}

output "client_cloud_config" {
  value = "${data.template_cloudinit_config.cloud_config.rendered}"
}
