resource "aws_s3_bucket" "director_blobstore_bucket" {
  count = 1

  bucket        = "${local.bucket_env_name}-director-blobstore-bucket-${var.bucket_suffix}"
  force_destroy = true


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

resource "aws_s3_bucket" "director_backup_blobstore_bucket" {
  count = 1

  bucket        = "${local.bucket_env_name}-director-backup-blobstore-bucket-${var.bucket_suffix}"
  force_destroy = true

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
    "Name" = "Director Backup Blobstore Bucket"
  },
  )
}

resource "aws_s3_bucket" "buildpacks_bucket" {
  count = 1

  bucket        = "${local.bucket_env_name}-buildpacks-bucket-${var.bucket_suffix}"
  force_destroy = true

  versioning {
    enabled = var.create_versioned_pas_buckets
  }

  logging {
    target_bucket = var.s3_logs_bucket
    target_prefix = "log/"
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

  bucket        = "${local.bucket_env_name}-droplets-bucket-${var.bucket_suffix}"
  force_destroy = true

  versioning {
    enabled = var.create_versioned_pas_buckets
  }

  logging {
    target_bucket = var.s3_logs_bucket
    target_prefix = "log/"
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

  bucket        = "${local.bucket_env_name}-packages-bucket-${var.bucket_suffix}"
  force_destroy = true

  versioning {
    enabled = var.create_versioned_pas_buckets
  }

  logging {
    target_bucket = var.s3_logs_bucket
    target_prefix = "log/"
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

  bucket        = "${local.bucket_env_name}-resources-bucket-${var.bucket_suffix}"
  force_destroy = true

  versioning {
    enabled = var.create_versioned_pas_buckets
  }

  logging {
    target_bucket = var.s3_logs_bucket
    target_prefix = "log/"
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
  bucket        = "${local.bucket_env_name}-buildpacks-backup-bucket-${var.bucket_suffix}"
  force_destroy = true

  count = var.create_backup_pas_buckets ? 1 : 0

  logging {
    target_bucket = var.s3_logs_bucket
    target_prefix = "log/"
  }

  tags = merge(
    var.tags,
    {
      "Name" = "Elastic Runtime S3 Buildpacks Backup Bucket"
    },
  )
}

resource "aws_s3_bucket" "droplets_backup_bucket" {
  bucket        = "${local.bucket_env_name}-droplets-backup-bucket-${var.bucket_suffix}"
  force_destroy = true

  count = var.create_backup_pas_buckets ? 1 : 0

  logging {
    target_bucket = var.s3_logs_bucket
    target_prefix = "log/"
  }

  tags = merge(
    var.tags,
    {
      "Name" = "Elastic Runtime S3 Droplets Backup Bucket"
    },
  )
}

resource "aws_s3_bucket" "packages_backup_bucket" {
  bucket        = "${local.bucket_env_name}-packages-backup-bucket-${var.bucket_suffix}"
  force_destroy = true

  count = var.create_backup_pas_buckets ? 1 : 0

  logging {
    target_bucket = var.s3_logs_bucket
    target_prefix = "log/"
  }

  tags = merge(
    var.tags,
    {
      "Name" = "Elastic Runtime S3 Packages Backup Bucket"
    },
  )
}

resource "aws_s3_bucket" "resources_backup_bucket" {
  bucket        = "${local.bucket_env_name}-resources-backup-bucket-${var.bucket_suffix}"
  force_destroy = true

  count = var.create_backup_pas_buckets ? 1 : 0

  logging {
    target_bucket = var.s3_logs_bucket
    target_prefix = "log/"
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
  bucket_env_name = replace(var.env_name, " ", "-")
}

