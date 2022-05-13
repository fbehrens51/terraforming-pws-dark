//After a lot of modifications, the approach we're taking here is as follows:
// The role & user variables are for cases where we want to restrict that action set to those users only
//Why? See: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html
//In short, access to resources are done as follows and can be within the iam policy or the bucket policy:
//1. If there is a Deny in the IAM policy or resource policy, the user is denied.
//2. If no explicit Deny, it will look for an Allow in the IAM policy and resource policy, if one exists, the user's action is allowed

variable "bucket_arn" { type = string }
variable "read_only_role_ids" {
  type    = list(string)
  default = []
}
variable "read_only_user_ids" {
  type    = list(string)
  default = []
}
variable "read_write_role_ids" {
  type    = list(string)
  default = []
}
variable "read_write_user_ids" {
  type    = list(string)
  default = []
}


variable "disable_delete" {
  type    = bool
  default = false
}

locals {
  #anyone with assume role permissions to the give role_ids
  read_only_role_wildcards = [
    for num in var.read_only_role_ids :
    "${num}:*"
  ]
  read_write_role_wildcards = [
    for num in var.read_write_role_ids :
    "${num}:*"
  ]
}

//NOTE:Ensure we do not deny the following actions.  These are used by a enterprise role in our account to audit bucket configuration
//      "s3:GetBucket*",
//      "s3:GetBucketLogging",
//      "s3:GetBucketPolicy",
//      "s3:GetBucketVersioning"
data "aws_iam_policy_document" "bucket_policy" {

  //Read Only statement
  //Deny everyone except for read (& write) users to retrieve Objects
  statement {
    sid     = "read"
    effect  = "Deny"
    actions = ["s3:GetObject*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringNotLike"
      variable = "aws:userid"
      values   = concat(local.read_write_role_wildcards, var.read_write_user_ids, local.read_only_role_wildcards, var.read_only_user_ids)
    }
    resources = ["${var.bucket_arn}/*"]
  }

  //Write statement
  //Deny everyone except write users.
  statement {
    sid     = "write"
    effect  = "Deny"
    actions = ["s3:PutObject*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringNotLike"
      variable = "aws:userid"
      values   = concat(local.read_write_role_wildcards, var.read_write_user_ids)
    }
    resources = [var.bucket_arn, "${var.bucket_arn}/*"]
  }

  // Enforce min TLS version
  statement {
    sid     = "EnforceTls"
    effect  = "Deny"
    actions = ["s3:*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = ["1.2"]
    }
    resources = [var.bucket_arn, "${var.bucket_arn}/*"]
  }
}

data "aws_iam_policy_document" "deletion_disabled" {
  source_json = data.aws_iam_policy_document.bucket_policy.json
  //Deletion statement
  //Deny everyone from deleting Objects or Bucket itself.
  statement {
    sid    = "deletion_disabled"
    effect = "Deny"
    actions = [
      "s3:DeleteBucket",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion"
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [var.bucket_arn, "${var.bucket_arn}/*"]
  }

  // Enforce min TLS version
  statement {
    sid     = "EnforceTls"
    effect  = "Deny"
    actions = ["s3:*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = ["1.2"]
    }
    resources = [var.bucket_arn, "${var.bucket_arn}/*"]
  }
}

output "json" {
  value = var.disable_delete ? data.aws_iam_policy_document.deletion_disabled.json : data.aws_iam_policy_document.bucket_policy.json
}
