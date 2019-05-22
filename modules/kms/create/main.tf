resource "aws_kms_alias" "kms_key_alias" {
  target_key_id = "${aws_kms_key.kms_key.key_id}"
  depends_on    = ["aws_kms_key.kms_key"]
  name_prefix   = "alias/${var.key_name}"
}

resource "aws_kms_key" "kms_key" {
  description             = "${var.key_name} KMS key"
  deletion_window_in_days = "${var.deletion_window}"

  tags = "${map("Name", "${var.key_name} KMS Key")}"
}

variable "key_name" {}

variable "deletion_window" {
  default = 7
}

output "kms_key_id" {
  value = "${aws_kms_key.kms_key.id}"
}

output "key_arn" {
  value = "${aws_kms_key.kms_key.arn}"
}
