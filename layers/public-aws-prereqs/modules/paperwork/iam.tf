data "aws_iam_policy_document" "director" {
  statement {
    effect = "Allow"

    actions = [
      "iam:GetServerCertificate",
      "iam:GetInstanceProfile",
      "iam:GetRole",
      "s3:*",
      "iam:ListServerCertificates",
      "rds:DescribeEngineDefaultParameters",
      "elasticloadbalancing:*",
      "rds:PurchaseReservedDBInstancesOffering",
      "iam:UploadServerCertificate",
      "iam:PassRole",
      "rds:DescribeDBClusterSnapshots",
      "rds:DescribeEngineDefaultClusterParameters",
      "rds:DescribeDBInstances",
      "rds:DescribeOrderableDBInstanceOptions",
      "iam:DeleteServerCertificate",
      "ec2:*",
      "rds:DownloadCompleteDBLogFile",
      "rds:DescribeCertificates",
      "rds:DescribeEventCategories",
      "rds:DescribeAccountAttributes",
      "kms:*",
      "elasticache:*",
      "logs:*",
      "cloudwatch:PutDashboard",
      "cloudwatch:GetDashboard",
      "cloudwatch:ListDashboards",
      "cloudwatch:DeleteDashboards",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:DescribeTable",
    ]

    resources = ["*"]
  }

  statement {
    effect  = "Allow"
    actions = ["rds:*"]

    resources = [
      "arn:aws:rds:*:*:snapshot:*",
      "arn:aws:rds:*:*:db:*",
      "arn:aws:rds:*:*:secgrp:*",
      "arn:aws:rds:*:*:cluster:*",
      "arn:aws:rds:*:*:subgrp:*",
      "arn:aws:rds:*:*:cluster-snapshot:*",
      "arn:aws:rds:*:*:og:*",
      "arn:aws:rds:*:*:ri:*",
      "arn:aws:rds:*:*:pg:*",
      "arn:aws:iam::*:role/*",
      "arn:aws:rds:*:*:es:*",
    ]
  }
}

data "aws_iam_policy_document" "bucket" {
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_caller_identity" "myself" {
}

data "aws_iam_policy_document" "user_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      # Allowing the root user effectively allows any user in that account.
      # Note: iam trust policy (or assume policy) does not accept wildcards in
      # the Principal
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.myself.account_id}:root"]

      type = "AWS"
    }
  }
}

resource "aws_iam_policy" "director" {
  name   = var.director_role_name
  path   = "/"
  policy = data.aws_iam_policy_document.director.json
}

resource "aws_iam_role" "director" {
  name               = var.director_role_name
  assume_role_policy = data.aws_iam_policy_document.role_policy.json
}

resource "aws_iam_policy_attachment" "director" {
  name       = var.director_role_name
  roles      = [aws_iam_role.director.name]
  policy_arn = aws_iam_policy.director.arn
}

resource "aws_iam_role_policy_attachment" "director_ecr" {
  role       = aws_iam_role.director.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_instance_profile" "director" {
  name = var.director_role_name
  role = aws_iam_role.director.name
}

resource "aws_iam_instance_profile" "worker" {
  name = var.worker_role_name
  role = aws_iam_role.director.name
}

resource "aws_iam_instance_profile" "bucket" {
  name = var.bucket_role_name
  role = aws_iam_role.bucket.name
}

data "aws_iam_policy_document" "fluentd" {
  statement {
    effect = "Allow"

    actions = [
      "logs:*",
      "s3:*",
      "ec2:CreateTags",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "fluentd" {
  name   = var.fluentd_role_name
  path   = "/"
  policy = data.aws_iam_policy_document.fluentd.json
}

resource "aws_iam_role" "fluentd" {
  name               = var.fluentd_role_name
  assume_role_policy = data.aws_iam_policy_document.role_policy.json
}

resource "aws_iam_policy_attachment" "fluentd" {
  name       = var.fluentd_role_name
  roles      = [aws_iam_role.fluentd.name]
  policy_arn = aws_iam_policy.fluentd.arn
}

resource "aws_iam_instance_profile" "fluentd" {
  name = var.fluentd_role_name
  role = aws_iam_role.fluentd.name
}

resource "aws_iam_policy" "bucket" {
  name   = var.bucket_role_name
  path   = "/"
  policy = data.aws_iam_policy_document.bucket.json
}

resource "aws_iam_role" "bucket" {
  name               = var.bucket_role_name
  assume_role_policy = data.aws_iam_policy_document.role_policy.json
}

resource "aws_iam_policy_attachment" "bucket" {
  name       = var.bucket_role_name
  roles      = [aws_iam_role.bucket.name]
  policy_arn = aws_iam_policy.bucket.arn
}

data "aws_iam_policy_document" "kms_admin_user" {
  statement {
    effect = "Allow"

    actions = [
      "kms:*",
      "iam:ListUsers",
      "iam:ListRoles",
      "iam:ListGroups",
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "ec2_reader" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:Get*",
      "ec2:Describe*",
      "cloudwatch:DescribeAlarmsForMetric",
      "cloudwatch:DescribeAlarmHistory",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:GetMetricData",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "tsdb_writer" {
  name   = var.tsdb_role_name
  path   = "/"
  policy = data.aws_iam_policy_document.ec2_reader.json
}

resource "aws_iam_role" "tsdb_role" {
  name               = var.tsdb_role_name
  assume_role_policy = data.aws_iam_policy_document.role_policy.json
}

resource "aws_iam_policy_attachment" "tsdb" {
  name       = var.tsdb_role_name
  roles      = [aws_iam_role.tsdb_role.name]
  policy_arn = aws_iam_policy.tsdb_writer.arn
}

resource "aws_iam_instance_profile" "tsdb_instance_profile" {
  name = aws_iam_role.tsdb_role.name
  role = aws_iam_role.tsdb_role.name
}

data "aws_iam_policy_document" "s3_reader" {
  statement {
    effect = "Allow"

    actions = [
      "s3:Get*",
      "s3:List*",
    ]

    resources = ["*"]
  }
}

output "director_role_arn" {
  value = aws_iam_role.director.arn
}

output "pas_bucket_role_arn" {
  value = aws_iam_role.bucket.arn
}


data "aws_iam_policy_document" "instance_tagger" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateTags",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "instance_tagger" {
  name   = var.instance_tagger_role_name
  path   = "/"
  policy = data.aws_iam_policy_document.instance_tagger.json
}

resource "aws_iam_role" "instance_tagger" {
  name               = var.instance_tagger_role_name
  assume_role_policy = data.aws_iam_policy_document.role_policy.json
}

resource "aws_iam_policy_attachment" "instance_tagger" {
  name       = var.instance_tagger_role_name
  roles      = [aws_iam_role.instance_tagger.name]
  policy_arn = aws_iam_policy.instance_tagger.arn
}

resource "aws_iam_instance_profile" "instance_tagger" {
  name = var.instance_tagger_role_name
  role = aws_iam_role.instance_tagger.name
}
