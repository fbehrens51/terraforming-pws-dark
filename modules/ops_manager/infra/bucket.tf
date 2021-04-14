locals {
  formatted_env_name           = replace(var.env_name, " ", "-")
  om_bucket_name               = "${local.formatted_env_name}-ops-manager-bucket-${var.bucket_suffix}"
  blobstore_bucket_name        = "${local.formatted_env_name}-director-blobstore-bucket-${var.bucket_suffix}"
  backup_blobstore_bucket_name = "${local.formatted_env_name}-director-blobstore-bucket-backup-${var.bucket_suffix}"
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

resource "aws_s3_bucket" "director_blobstore_bucket_backup" {
  bucket        = local.backup_blobstore_bucket_name
  force_destroy = var.force_destroy_buckets

  versioning {
    enabled = true
  }

  logging {
    target_bucket = var.s3_logs_bucket
    target_prefix = "${local.backup_blobstore_bucket_name}/"
  }

  tags = merge(
    var.tags,
    {
      "Name" = "Director Blobstore Bucket Backup"
    },
  )
}
