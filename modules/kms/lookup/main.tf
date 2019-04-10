data "aws_kms_alias" "blobstore_kms_key_alias" {
  name = "alias/${var.key_name}"
}

data "aws_kms_key" "kms_key" {
  key_id = "${data.aws_kms_alias.blobstore_kms_key_alias.target_key_id}"
}

variable "key_name" {}

output "kms_key_id" {
  value = "${data.aws_kms_key.kms_key.id}"
}
