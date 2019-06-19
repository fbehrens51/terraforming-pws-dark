resource "aws_kms_alias" "kms_key_alias" {
  target_key_id = "${aws_kms_key.kms_key.key_id}"
  depends_on    = ["aws_kms_key.kms_key"]
  name_prefix   = "alias/${var.key_name}"
}

data "aws_iam_role" "key_manager_role" {
  name = "${var.key_manager_role_name}"
}

data "aws_iam_role" "director_role" {
  name = "${var.director_role_name}"
}

data "aws_iam_role" "pas_bucket_role" {
  name = "${var.pas_bucket_role_name}"
}

data "aws_caller_identity" "my_account" {}

data "aws_iam_policy_document" "kms_key_policy_document" {
  # TODO: Figure out how to remove the following (default) policy statement.
  # If this statement is removed then terragrunt will have to run after
  # assuming the key manager role.  We will also have to give the key manager
  # role permission to access the S3 state bucket.  This will be addressed as
  # part of #166195427.
  statement {
    sid    = "Allow access for root user"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.my_account.account_id}:root",
      ]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

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
        "${data.aws_iam_role.key_manager_role.arn}",
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
  description             = "${var.key_name} KMS key"
  deletion_window_in_days = "${var.deletion_window}"
  policy                  = "${data.aws_iam_policy_document.kms_key_policy_document.json}"

  tags = "${map("Name", "${var.key_name} KMS Key")}"
}

variable "pas_bucket_role_name" {}
variable "director_role_name" {}
variable "key_manager_role_name" {}

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
