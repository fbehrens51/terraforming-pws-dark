locals {
  formatted_env_name = replace(var.env_name, " ", "-")
}

resource "aws_s3_bucket" "ops_manager_bucket" {
  bucket        = "${local.formatted_env_name}-ops-manager-bucket-${var.bucket_suffix}"
  force_destroy = true

  logging {
    target_bucket = var.s3_logs_bucket
    target_prefix = "log/"
  }

  tags = merge(
    var.tags,
    {
      "Name" = "Ops Manager S3 Bucket"
    },
  )
}

