resource "aws_kms_alias" "kms_key_alias" {
  target_key_id = "${aws_kms_key.kms_key.key_id}"
  depends_on    = ["aws_kms_key.kms_key"]
  name_prefix   = "alias/${var.key_name}"
}

data "aws_iam_role" "director_role" {
  name = "${var.director_role_name}"
}

data "aws_iam_role" "pas_bucket_role" {
  name = "${var.pas_bucket_role_name}"
}

data "aws_caller_identity" "my_account" {}

data "aws_iam_policy_document" "kms_key_policy_document" {
  # the following actions were inspired by https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html#key-policy-default-allow-users
  statement {
    sid    = "Allow access for key users"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "${data.aws_iam_role.director_role.arn}",
        "${data.aws_iam_role.pas_bucket_role.arn}",
      ]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    resources = ["*"]
  }

  # the following actions were inspired by https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html#key-policy-default-allow-administrators
  statement {
    sid    = "Allow access for key managers"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        # This layer should be run with the credentials of the key manager.
        "${data.aws_caller_identity.my_account.arn}",
      ]
    }

    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
    ]

    resources = ["*"]
  }
}

resource "aws_kms_key" "kms_key" {
  count = 1

  description             = "${var.key_name} KMS key"
  deletion_window_in_days = "${var.deletion_window}"
  policy                  = "${data.aws_iam_policy_document.kms_key_policy_document.json}"

  tags = "${map("Name", "${var.key_name} KMS Key")}"
}

variable "pas_bucket_role_name" {}
variable "director_role_name" {}

variable "key_name" {}

variable "deletion_window" {
  default = 7
}

output "kms_key_id" {
  value = "${element(concat(aws_kms_key.kms_key.*.id, list("")), 0)}"
}
