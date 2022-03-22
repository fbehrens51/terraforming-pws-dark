variable "artifact_repo_bucket_name" {
  type = string
  default = "testing_repo_bucket"
}

variable "force_destroy_buckets" {
  type    = bool
  default = false
}

variable "read_only_arns" {
  type    = list(string)
  default = []
}

variable "read_write_arns" {
  type    = list(string)
  default = []
}

resource "aws_s3_bucket" "s3_logs_bucket" {
  bucket        = "${var.artifact_repo_bucket_name}-s3-logs"
  acl           = "log-delivery-write"
  force_destroy = var.force_destroy_buckets

  //use account's default S3 encryption key
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  tags = {
    "Name" = "${var.artifact_repo_bucket_name} S3 Logs Bucket"
  }
}

data "aws_iam_policy_document" "arn_bucket_policy" {


  //Read Only statement
  //Deny everyone except for read (& write) users to retrieve Objects
  statement {
    sid     = "ARNread"
    effect  = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:GetObject*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalARN"
      values   = concat(var.read_write_arns,var.read_only_arns)

    }
    resources = [aws_s3_bucket.artifact_repo.arn, "${aws_s3_bucket.artifact_repo.arn}/*"]
  }

  //Write statement
  //Deny everyone except write users.
  statement {
    sid     = "ARNwrite"
    effect  = "Allow"
    actions = [
      "s3:*"
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalARN"
      values   = var.read_write_arns
    }
    resources = [aws_s3_bucket.artifact_repo.arn, "${aws_s3_bucket.artifact_repo.arn}/*"]
  }
}


resource "aws_s3_bucket" "artifact_repo" {
  bucket = var.artifact_repo_bucket_name
  force_destroy = var.force_destroy_buckets

  //use account's default S3 encryption key
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  logging {
    target_bucket = aws_s3_bucket.s3_logs_bucket.bucket
    target_prefix = "${var.artifact_repo_bucket_name}/"
  }

  tags = merge(
  {
    "Name" = var.artifact_repo_bucket_name
  },
  )
}


resource "aws_s3_bucket_policy" "artifact_repo_bucket_policy_attachment" {
  bucket = aws_s3_bucket.artifact_repo.bucket
  policy = data.aws_iam_policy_document.arn_bucket_policy.json
}

