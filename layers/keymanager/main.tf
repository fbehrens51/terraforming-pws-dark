
provider "aws" {
}

module "providers" {
  source = "../../modules/dark_providers"
}

terraform {
  backend "s3" {
  }
}

data "aws_caller_identity" "my_account"{}


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
        var.promoter_role_arn
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


resource "aws_kms_key" "transfer_kms_key" {
  policy = "${data.aws_iam_policy_document.kms_key_policy_document.json}"
  description = "TRANSFER_KMS_KEY"
}

variable "director_role_arn" {}
variable "promoter_role_arn" {}


output "transfer_key_arn" {
  value = aws_kms_key.transfer_kms_key.arn
}