variable "splunk_rpm_s3_bucket" {}
variable "splunk_rpm_version" {}
variable "splunk_rpm_s3_region" {}
variable "admin_password" {}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    splunk_rpm_s3_bucket = "${var.splunk_rpm_s3_bucket}"
    splunk_rpm_version   = "${var.splunk_rpm_version}"
    splunk_rpm_s3_region = "${var.splunk_rpm_s3_region}"
    admin_password       = "${var.admin_password}"
  }
}

output "user_data" {
  value = "${data.template_file.user_data.rendered}"
}
