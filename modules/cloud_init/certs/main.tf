variable "public_bucket_name" {
}

variable "public_bucket_url" {
}

variable "ca_chain" {
}

data "template_file" "user_data" {
  template = file("${path.module}/user_data.tpl")

  vars = {
    ca_chain = var.ca_chain
  }
}

data "template_cloudinit_config" "cloud_config" {
  base64_encode = false
  gzip          = false

  part {
    content    = data.template_file.user_data.rendered
    merge_type = "list(append)+dict(no_replace,recurse_list)"
  }
}

locals {
  bucket_key = "amazon2-system-certs-${md5(data.template_file.user_data.rendered)}-user-data.yml"
}

resource "aws_s3_bucket_object" "user_data" {
  bucket  = var.public_bucket_name
  key     = local.bucket_key
  content = data.template_file.user_data.rendered
}

output "amazon2_system_certs_user_data" {
  value = <<EOF
#include
${var.public_bucket_url}/${local.bucket_key}
EOF

}

