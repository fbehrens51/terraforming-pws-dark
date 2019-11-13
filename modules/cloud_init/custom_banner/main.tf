data "template_file" "custom_banner_user_data_part" {
  template = <<EOF
#cloud-config
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]
write_files:
- path: /run/prompt.conf
  content: |
    ${indent(4, var.ssh_banner)}

runcmd:
  - |
    cp /run/prompt.conf /etc/issue.net
    sed -i 's|^#Banner .*|Banner /etc/issue.net|' /etc/ssh/sshd_config
    pkill -P 1 -SIGHUP sshd
EOF
}

variable "ssh_banner" {}
variable "public_bucket_name" {}
variable "public_bucket_url" {}

locals {
  bucket_key = "custom_banner-${md5(data.template_file.custom_banner_user_data_part.rendered)}-user-data.yml"
}

resource "aws_s3_bucket_object" "user_data" {
  bucket  = "${var.public_bucket_name}"
  key     = "${local.bucket_key}"
  content = "${data.template_file.custom_banner_user_data_part.rendered}"
}

output "custom_banner_user_data" {
  value = <<EOF
#include
${var.public_bucket_url}/${local.bucket_key}
EOF
}
