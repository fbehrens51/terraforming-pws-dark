locals {
  formatted_env_name = replace(var.env_name, " ", "-")
}

resource "aws_s3_bucket" "ops_manager_bucket" {
  bucket        = "${local.formatted_env_name}-ops-manager-bucket-${var.bucket_suffix}"
  force_destroy = var.force_destroy_buckets

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

resource "aws_s3_bucket" "director_blobstore_bucket" {
  bucket        = "${local.formatted_env_name}-director-blobstore-bucket-${var.bucket_suffix}"
  force_destroy = var.force_destroy_buckets

  versioning {
    enabled = true
  }

  logging {
    target_bucket = var.s3_logs_bucket
    target_prefix = "log/"
  }

  tags = merge(
    var.tags,
    {
      "Name" = "Director Blobstore Bucket"
    },
  )
}

resource "aws_s3_bucket" "director_blobstore_bucket_backup" {
  bucket        = "${local.formatted_env_name}-director-blobstore-bucket-backup-${var.bucket_suffix}"
  force_destroy = var.force_destroy_buckets

  versioning {
    enabled = true
  }

  logging {
    target_bucket = var.s3_logs_bucket
    target_prefix = "log/"
  }

  tags = merge(
    var.tags,
    {
      "Name" = "Director Blobstore Bucket Backup"
    },
  )
}
