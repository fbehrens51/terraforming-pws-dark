locals {
  formatted_env_name    = replace(var.env_name, " ", "-")
  om_bucket_name        = "${local.formatted_env_name}-ops-manager-bucket-${var.bucket_suffix_name}"
  blobstore_bucket_name = "${local.formatted_env_name}-director-blobstore-bucket-${var.bucket_suffix_name}"
}

resource "aws_s3_bucket" "ops_manager_bucket" {
  bucket        = local.om_bucket_name
  force_destroy = var.force_destroy_buckets

  logging {
    target_bucket = var.s3_logs_bucket
    target_prefix = "${local.om_bucket_name}/"
  }

  tags = merge(
    var.tags,
    {
      "Name" = "Ops Manager S3 Bucket"
    },
  )
}

resource "aws_s3_bucket" "director_blobstore_bucket" {
  bucket        = local.blobstore_bucket_name
  force_destroy = var.force_destroy_buckets

  versioning {
    enabled = true
  }

  logging {
    target_bucket = var.s3_logs_bucket
    target_prefix = "${local.blobstore_bucket_name}/"
  }

  tags = merge(
    var.tags,
    {
      "Name" = "Director Blobstore Bucket"
    },
  )
}
