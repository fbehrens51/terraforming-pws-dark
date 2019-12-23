# Backup

data "template_file" "pas_backup_bucket_policy" {
  template = file(
    "${path.module}/templates/iam_pas_backup_buckets_policy.json",
  )

  vars = {
    buildpacks_backup_bucket_arn = aws_s3_bucket.buildpacks_backup_bucket[0].arn
    droplets_backup_bucket_arn   = aws_s3_bucket.droplets_backup_bucket[0].arn
    packages_backup_bucket_arn   = aws_s3_bucket.packages_backup_bucket[0].arn
    resources_backup_bucket_arn  = aws_s3_bucket.resources_backup_bucket[0].arn
  }

  count = var.create_backup_pas_buckets ? 1 : 0
}

