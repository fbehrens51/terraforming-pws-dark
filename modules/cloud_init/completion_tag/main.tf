variable "public_bucket_name" {
}

variable "public_bucket_url" {
}

locals {
  bucket_key = "completion_tag.yml"
  ud_file    = file("${path.module}/completion-tag.tpl")
}

resource "aws_s3_bucket_object" "user_data" {
  bucket  = var.public_bucket_name
  key     = local.bucket_key
  content = local.ud_file
}

output "tg_include_user_data" {
  value = <<EOF
#include
${var.public_bucket_url}/completion_tag.yml
EOF
}
