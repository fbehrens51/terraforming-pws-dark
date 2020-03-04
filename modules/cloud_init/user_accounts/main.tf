variable "user_accounts_user_data" {
  type = list(string)
}

variable "public_bucket_name" {
}

variable "public_bucket_url" {
}

locals {
  bucket_key = [for user_data in var.user_accounts_user_data : "user_accounts-${md5(user_data)}-user-data.yml"]
}

resource "aws_s3_bucket_object" "user_data" {
  count   = length(var.user_accounts_user_data)
  bucket  = var.public_bucket_name
  key     = local.bucket_key[count.index]
  content = var.user_accounts_user_data[count.index]
}

output "user_accounts_user_data" {
  value = <<EOF
#include
%{for key in local.bucket_key~}
${var.public_bucket_url}/${key}
%{endfor~}
EOF

}

