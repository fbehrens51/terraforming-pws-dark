variable "bucket_arn" { type = string }
variable "director_role_id" { type = string }
variable "read_only_role_ids" {
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
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:ListBucket"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringLike"
      variable = "aws:userid"
      values   = local.read_only_role_wildcards

    }
    resources = [var.bucket_arn, "${var.bucket_arn}/*"]
  }

  statement {
    effect  = "Allow"
    actions = ["s3:*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringLike"
      variable = "aws:userid"
      values   = concat(["${var.director_role_id}:*"], var.super_user_ids, local.super_user_role_wildcards)
    }
    resources = [var.bucket_arn, "${var.bucket_arn}/*"]
  }

  statement {
    effect  = "Deny"
    actions = ["s3:*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringNotLike"
      variable = "aws:userid"
      values   = concat(["${var.director_role_id}:*"], local.read_only_role_wildcards, var.super_user_ids, local.super_user_role_wildcards)
    }
    resources = [var.bucket_arn, "${var.bucket_arn}/*"]
  }
}

output "json" {
  value = data.aws_iam_policy_document.bucket_policy.json
}