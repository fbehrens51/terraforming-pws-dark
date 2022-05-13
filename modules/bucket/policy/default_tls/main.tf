variable "bucket_arn" {
  type = string
}

data "aws_iam_policy_document" "tls_bucket_policy" {

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
  value = data.aws_iam_policy_document.tls_bucket_policy.json
}
