variable "user_accounts_user_data" {
}

variable "public_bucket_name" {
}

variable "public_bucket_url" {
}

locals {
  bucket_key = "user_accounts-${md5(var.user_accounts_user_data)}-user-data.yml"
}

resource "aws_s3_bucket_object" "user_data" {
  bucket  = var.public_bucket_name
  key     = local.bucket_key
  content = var.user_accounts_user_data
}

output "user_accounts_user_data" {
  value = <<EOF
#include
${var.public_bucket_url}/${local.bucket_key}
EOF

}

