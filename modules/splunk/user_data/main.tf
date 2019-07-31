//TODO: Add timeout ~ 5minutes for user data to fail
data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    password = "${random_string.splunk_password.result}"
  }
}

data "template_cloudinit_config" "splunk_conf_userdata" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "splunk_conf.cfg"
    content_type = "text/cloud-config"
    content      = "${data.template_file.user_data.rendered}"
  }
}

resource "random_string" "splunk_password" {
  length  = "32"
  special = false
}

output "user_data" {
  //  value = "${data.template_file.user_data.rendered}"
  value = "${data.template_cloudinit_config.splunk_conf_userdata.rendered}"
}

output "password" {
  value     = "${random_string.splunk_password.result}"
  sensitive = true
}
