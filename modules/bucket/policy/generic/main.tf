variable "bucket_arn" { type = string }
variable "read_only_role_ids" {
  type    = list(string)
  default = []
}
variable "read_write_role_ids" {
  type    = list(string)
  default = []
}
variable "super_user_ids" {
  type    = list(string)
  default = []
}
variable "super_user_role_ids" {
  type    = list(string)
  default = []
}
variable "tech_read_role_ids" {
  type    = list(string)
  default = []
}

variable "disable_delete" {
  type    = bool
  default = false
}

//TODO: another statement to support bucket management and not read/write instead of *
locals {
  #anyone with assume role permissions to the give role_ids
  read_only_role_wildcards = [
    for num in var.read_only_role_ids :
    "${num}:*"
  ]

  super_user_role_wildcards = [
    for num in var.super_user_role_ids :
    "${num}:*"
  ]
  read_write_role_wildcards = [
    for num in var.read_write_role_ids :
    "${num}:*"
  ]
  tech_read_wildcards = [
    for num in var.tech_read_role_ids :
    "${num}:*"
  ]
}

data "aws_iam_policy_document" "bucket_policy" {

  //Enterprise Tech Read
  statement {
    sid    = "tech_read"
    effect = "Allow"
    actions = [
      "s3:GetBucketAcl",
      "s3:GetBucketLogging",
      "s3:GetBucketPolicy",
      "s3:GetBucketVersioning"
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringLike"
      variable = "aws:userid"
      values   = concat(local.tech_read_wildcards)

    }
    resources = [var.bucket_arn]
  }

  //Read Only statement
  statement {
    sid     = "read_only"
    effect  = "Allow"
    actions = ["s3:Get*", "s3:List*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringLike"
      variable = "aws:userid"
      values   = concat(local.read_write_role_wildcards, local.read_only_role_wildcards)

    }
    resources = [var.bucket_arn, "${var.bucket_arn}/*"]
  }

  statement {
    sid     = "write"
    effect  = "Allow"
    actions = ["s3:Put*", "s3:PutObjectAcl"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringLike"
      variable = "aws:userid"
      values   = concat(local.read_write_role_wildcards)
    }
    resources = [var.bucket_arn, "${var.bucket_arn}/*"]
  }

  statement {
    sid    = "super_user"
    effect = "Allow"
    //    TODO: more fine grain access?
    //    actions = ["s3:CreateBucket","s3:ListAllMyBuckets","s3:GetBucketLocation"]
    actions = ["s3:*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringLike"
      variable = "aws:userid"
      values   = concat(var.super_user_ids, local.super_user_role_wildcards)
    }
    resources = [var.bucket_arn, "${var.bucket_arn}/*"]
  }

  statement {
    sid     = "bucket_deny_all_but"
    effect  = "Deny"
    actions = ["s3:*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringNotLike"
      variable = "aws:userid"
      values   = concat(local.read_write_role_wildcards, local.read_only_role_wildcards, var.super_user_ids, local.super_user_role_wildcards, local.tech_read_wildcards)
    }
    resources = [var.bucket_arn]
  }

  statement {
    sid     = "objects_deny_all_but"
    effect  = "Deny"
    actions = ["s3:*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringNotLike"
      variable = "aws:userid"
      values   = concat(local.read_write_role_wildcards, local.read_only_role_wildcards, var.super_user_ids, local.super_user_role_wildcards)
    }
    resources = ["${var.bucket_arn}/*"]
  }
}

data "aws_iam_policy_document" "deletion_disabled" {
  source_json = data.aws_iam_policy_document.bucket_policy.json
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
  //  override_json = data.aws_iam_policy_document.super_but_not_write.json

  //  TODO: once we get to aws provider version 3.x we can use the following approach to merge a list of policy documents
  //  source_policy_documents = [
  //    var.disable_delete ? module.disable_delete.json: "",
  //    data.aws_iam_policy_document.bucket_policy.json
  //  ]
}

data "aws_iam_policy_document" "super_but_not_write" {
  statement {
    sid    = "super_user"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:PutBucket*",
      "s3:PutLifecycleConfiguration"
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringLike"
      variable = "aws:userid"
      values   = concat(var.super_user_ids, local.super_user_role_wildcards)
    }
    resources = [var.bucket_arn, "${var.bucket_arn}/*"]
  }
}

output "json" {
  value = var.disable_delete ? data.aws_iam_policy_document.deletion_disabled.json : data.aws_iam_policy_document.bucket_policy.json
}