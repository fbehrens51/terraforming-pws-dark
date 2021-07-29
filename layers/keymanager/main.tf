provider "aws" {
}

module "providers" {
  source = "../../modules/dark_providers"
}

terraform {
  backend "s3" {
  }
}

data "aws_caller_identity" "my_account" {}

data "template_file" "keymanager_output_variables" {
  template = file("${path.module}/keymanager_output.tfvars.tpl")
  vars = {
    kms_key_id       = module.keys.kms_key_id
    kms_key_arn      = module.keys.kms_key_arn
    transfer_key_arn = aws_kms_key.transfer_kms_key.arn
  }
}

resource "local_file" "keymanager_output_variable_file" {
  filename = var.keymanager_file_output_path
  content  = data.template_file.keymanager_output_variables.rendered
}

# We invoke the keys layer here to simulate having a KEYMANAGER role invoke keys
# "out of band" in the production environment
module "keys" {
  source = "../../modules/kms/create"

  key_name                           = var.pas_kms_key_name
  director_role_arn                  = var.director_role_arn
  pas_bucket_role_arn                = var.pas_bucket_role_arn
  sjb_role_arn                       = var.sjb_role_arn
  concourse_role_arn                 = var.concourse_role_arn
  om_role_arn                        = var.om_role_arn
  bosh_role_arn                      = var.bosh_role_arn
  deletion_window                    = "7"
  additional_bootstrap_principal_arn = data.aws_caller_identity.my_account.arn
  logs_service_name                  = var.logs_service_name

  bootstrap_role_arn  = var.bootstrap_role_arn
  foundation_role_arn = var.foundation_role_arn
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
        var.sjb_role_arn,
        var.concourse_role_arn,
        var.om_role_arn,
        var.bosh_role_arn,
        var.bootstrap_role_arn,
        var.foundation_role_arn,
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
        var.promoter_role_arn,
        var.bootstrap_role_arn,
        var.foundation_role_arn,
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
  policy      = data.aws_iam_policy_document.kms_key_policy_document.json
  description = "TRANSFER_KMS_KEY"
}

variable "director_role_arn" {}
variable "bootstrap_role_arn" {}
variable "foundation_role_arn" {}
variable "promoter_role_arn" {}
variable "pas_bucket_role_arn" {}
variable "sjb_role_arn" {}
variable "concourse_role_arn" {}
variable "om_role_arn" {}
variable "bosh_role_arn" {}
variable "pas_kms_key_name" {}
variable "keymanager_file_output_path" {}
variable "logs_service_name" {
}

output "transfer_key_arn" {
  value = aws_kms_key.transfer_kms_key.arn
}
