variable "clamav_db_mirror" {}
variable "custom_repo_url" {}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    clam_database_mirror = "${var.clamav_db_mirror}"
    clam_freshclam       = "${indent(8,file("${path.module}/clam-freshclam"))}"
    custom_repo_url      = "${var.custom_repo_url}"
  }
}

data "template_cloudinit_config" "cloud_config" {
  base64_encode = false
  gzip          = false

  part {
    content    = "${data.template_file.user_data.rendered}"
    merge_type = "list(append)+dict(no_replace,recurse_list)"
  }
}

output "client_user_data_config" {
  value = "${data.template_file.user_data.rendered}"
}

output "client_cloud_config" {
  value = "${data.template_cloudinit_config.cloud_config.rendered}"
}
