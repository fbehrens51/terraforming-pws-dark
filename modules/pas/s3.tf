resource "aws_s3_bucket" "buildpacks_bucket" {
  count = 1

  bucket        = local.buildpacks_bucket_name
  force_destroy = var.force_destroy_buckets

  versioning {
    enabled = var.create_versioned_pas_buckets
  }

  logging {
    target_bucket = var.s3_logs_bucket
    target_prefix = "${local.buildpacks_bucket_name}/"
  }

  tags = merge(
    var.tags,
    {
      "Name" = "Elastic Runtime S3 Buildpacks Bucket"
    },
  )
}

resource "aws_s3_bucket" "droplets_bucket" {
  count = 1

  bucket        = local.droplets_bucket_name
  force_destroy = var.force_destroy_buckets

  versioning {
    enabled = var.create_versioned_pas_buckets
  }

  logging {
    target_bucket = var.s3_logs_bucket
    target_prefix = "${local.droplets_bucket_name}/"
  }

  tags = merge(
    var.tags,
    {
      "Name" = "Elastic Runtime S3 Droplets Bucket"
    },
  )
}

resource "aws_s3_bucket" "packages_bucket" {
  count = 1

  bucket        = local.packages_bucket_name
  force_destroy = var.force_destroy_buckets

  versioning {
    enabled = var.create_versioned_pas_buckets
  }

  logging {
    target_bucket = var.s3_logs_bucket
    target_prefix = "${local.packages_bucket_name}/"
  }

  tags = merge(
    var.tags,
    {
      "Name" = "Elastic Runtime S3 Packages Bucket"
    },
  )
}

resource "aws_s3_bucket" "resources_bucket" {
  count = 1

  bucket        = local.resources_bucket_name
  force_destroy = var.force_destroy_buckets

  versioning {
    enabled = var.create_versioned_pas_buckets
  }

  logging {
    target_bucket = var.s3_logs_bucket
    target_prefix = "${local.resources_bucket_name}/"
  }

  tags = merge(
    var.tags,
    {
      "Name" = "Elastic Runtime S3 Resources Bucket"
    },
  )

}

# BBR Buckets

resource "aws_s3_bucket" "buildpacks_backup_bucket" {
  bucket        = local.buildpacks_backup_bucket_name
  force_destroy = var.force_destroy_buckets

  count = var.create_backup_pas_buckets ? 1 : 0

  logging {
    target_bucket = var.s3_logs_bucket
    target_prefix = "${local.buildpacks_backup_bucket_name}/"
  }

  tags = merge(
    var.tags,
    {
      "Name" = "Elastic Runtime S3 Buildpacks Backup Bucket"
    },
  )
}

resource "aws_s3_bucket" "droplets_backup_bucket" {
  bucket        = local.droplets_backup_bucket_name
  force_destroy = var.force_destroy_buckets

  count = var.create_backup_pas_buckets ? 1 : 0

  logging {
    target_bucket = var.s3_logs_bucket
    target_prefix = "${local.droplets_backup_bucket_name}/"
  }

  tags = merge(
    var.tags,
    {
      "Name" = "Elastic Runtime S3 Droplets Backup Bucket"
    },
  )
}

resource "aws_s3_bucket" "packages_backup_bucket" {
  bucket        = local.packages_backup_bucket_name
  force_destroy = var.force_destroy_buckets

  count = var.create_backup_pas_buckets ? 1 : 0

  logging {
    target_bucket = var.s3_logs_bucket
    target_prefix = "${local.packages_backup_bucket_name}/"
  }

  tags = merge(
    var.tags,
    {
      "Name" = "Elastic Runtime S3 Packages Backup Bucket"
    },
  )
}

resource "aws_s3_bucket" "resources_backup_bucket" {
  bucket        = local.resources_backup_bucket_name
  force_destroy = var.force_destroy_buckets

  count = var.create_backup_pas_buckets ? 1 : 0

  logging {
    target_bucket = var.s3_logs_bucket
    target_prefix = "${local.resources_backup_bucket_name}/"
  }

  tags = merge(
    var.tags,
    {
      "Name" = "Elastic Runtime S3 Resources Backup Bucket"
    },
  )
}

locals {
  //Bucket Names are not allowed to contain spaces
  bucket_env_name               = replace(var.env_name, " ", "-")
  buildpacks_bucket_name        = "${local.bucket_env_name}-buildpacks-bucket-${var.bucket_suffix}"
  droplets_bucket_name          = "${local.bucket_env_name}-droplets-bucket-${var.bucket_suffix}"
  packages_bucket_name          = "${local.bucket_env_name}-packages-bucket-${var.bucket_suffix}"
  resources_bucket_name         = "${local.bucket_env_name}-resources-bucket-${var.bucket_suffix}"
  buildpacks_backup_bucket_name = "${local.bucket_env_name}-buildpacks-backup-bucket-${var.bucket_suffix}"
  droplets_backup_bucket_name   = "${local.bucket_env_name}-droplets-backup-bucket-${var.bucket_suffix}"
  packages_backup_bucket_name   = "${local.bucket_env_name}-packages-backup-bucket-${var.bucket_suffix}"
  resources_backup_bucket_name  = "${local.bucket_env_name}-resources-backup-bucket-${var.bucket_suffix}"
}
