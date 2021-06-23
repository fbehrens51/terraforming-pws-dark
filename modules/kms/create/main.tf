resource "aws_kms_alias" "kms_key_alias" {
  target_key_id = aws_kms_key.kms_key[0].key_id
  depends_on    = [aws_kms_key.kms_key]
  name_prefix   = "alias/${var.key_name}"
}

data "aws_caller_identity" "my_account" {
}

data "aws_iam_policy_document" "kms_key_policy_document" {
  # This statement from the EBS docs here: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSEncryption.html
  # the statement is required in order to use a kms key for ebs volume encryption
  statement {
    effect  = "Allow"
    actions = ["kms:CreateGrant"]

    principals {
      type = "AWS"

      identifiers = [
        var.director_role_arn,
        var.om_role_arn,
        var.concourse_role_arn,
        var.sjb_role_arn,
        var.bosh_role_arn
      ]
    }

    resources = ["*"]

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }

  # the following actions were inspired by https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html#key-policy-default-allow-users
  statement {
    sid    = "Allow access for key users"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        var.director_role_arn,
        var.sjb_role_arn,
        var.concourse_role_arn,
        var.om_role_arn,
        var.bosh_role_arn,
        var.pas_bucket_role_arn,
        var.additional_bootstrap_principal_arn,
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

  statement {
    sid    = "Allow encrypting log groups with the KMS key"
    effect = "Allow"

    principals {
      type = "Service"
      # TODO: make the service configurable
      identifiers = [var.logs_service_name]
    }

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]

    resources = ["*"]
  }

  # the following actions were inspired by https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html#key-policy-default-allow-administrators
  statement {
    sid    = "Allow access for key managers"
    effect = "Allow"

    principals {
      type = "AWS"

      # This layer should be run with the credentials of the key manager.
      identifiers = [
        data.aws_caller_identity.my_account.arn,
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
  deletion_window_in_days = var.deletion_window
  policy                  = data.aws_iam_policy_document.kms_key_policy_document.json

  tags = {
    "Name" = "${var.key_name} KMS Key"
  }
}

variable "pas_bucket_role_arn" {
}

variable "director_role_arn" {
}

variable "om_role_arn" {}

variable "bosh_role_arn" {}

variable "sjb_role_arn" {}

variable "concourse_role_arn" {}

variable "additional_bootstrap_principal_arn" {
  default = ""
}

variable "key_name" {
}

variable "deletion_window" {
  default = 7
}

variable "logs_service_name" {
}

output "kms_key_arn" {
  value = aws_kms_key.kms_key[0].arn
}

output "kms_key_id" {
  value = aws_kms_key.kms_key[0].id
}

