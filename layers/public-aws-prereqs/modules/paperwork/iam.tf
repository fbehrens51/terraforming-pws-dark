data "aws_iam_policy_document" "bootstrap" {
  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:DeleteDashboards",
      "cloudwatch:GetDashboard",
      "cloudwatch:ListDashboards",
      "cloudwatch:PutDashboard",
      "ec2:*",
      "elasticache:*",
      "elasticloadbalancing:*",
      "iam:AttachRolePolicy",
      "iam:DeleteServerCertificate",
      "iam:DetachRolePolicy",
      "iam:GetInstanceProfile",
      "iam:GetPolicy",
      "iam:GetRole",
      "iam:GetServerCertificate",
      "iam:GetUser",
      "iam:ListAttachedRolePolicies",
      "iam:ListEntitiesForPolicy",
      "iam:ListRolePolicies",
      "iam:ListServerCertificates",
      "iam:PassRole",
      "iam:UploadServerCertificate",
      "kms:*",
      "logs:*",
      "rds:DescribeAccountAttributes",
      "rds:DescribeCertificates",
      "rds:DescribeDBClusterSnapshots",
      "rds:DescribeDBInstances",
      "rds:DescribeEngineDefaultClusterParameters",
      "rds:DescribeEngineDefaultParameters",
      "rds:DescribeEventCategories",
      "rds:DescribeOrderableDBInstanceOptions",
      "rds:DownloadCompleteDBLogFile",
      "rds:PurchaseReservedDBInstancesOffering",
      "s3:*",
      "sqs:*",
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

resource "aws_iam_policy" "bootstrap" {
  name   = var.bootstrap_role_name
  path   = "/"
  policy = data.aws_iam_policy_document.bootstrap.json
}

resource "aws_iam_role" "bootstrap" {
  name               = var.bootstrap_role_name
  assume_role_policy = data.aws_iam_policy_document.role_policy.json
}

resource "aws_iam_policy_attachment" "bootstrap" {
  name       = var.bootstrap_role_name
  roles      = [aws_iam_role.bootstrap.name]
  policy_arn = aws_iam_policy.bootstrap.arn
}

resource "aws_iam_role_policy_attachment" "bootstrap_ecr" {
  role       = aws_iam_role.bootstrap.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_instance_profile" "bootstrap" {
  name = var.bootstrap_role_name
  role = aws_iam_role.bootstrap.name
}

data "aws_iam_policy_document" "director" {
  statement {
    effect = "Allow"

    actions = [
      "iam:GetServerCertificate",
      "iam:GetInstanceProfile",
      "iam:GetRole",
      "iam:GetUser",
      "iam:GetPolicy",
      "s3:*",
      "sqs:*",
      "iam:ListServerCertificates",
      "iam:ListEntitiesForPolicy",
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
      "iam:DetachRolePolicy",
      "iam:AttachRolePolicy",
      "iam:ListRolePolicies",
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

data "aws_iam_policy_document" "isse" {
  statement {
    effect = "Allow"

    actions = [
      "s3:Get*",
      "s3:List*",
      "logs:Describe*",
      "logs:Get*",
      "logs:List*",
      "logs:StartQuery",
      "logs:StopQuery",
      "logs:TestMetricFilter",
      "logs:FilterLogEvents",

      // AmazonEC2ReadOnlyAccess
      "ec2:Describe*",
      "elasticloadbalancing:Describe*",
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:Describe*",
      "autoscaling:Describe*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "isse" {
  name   = var.isse_role_name
  path   = "/"
  policy = data.aws_iam_policy_document.isse.json
}

resource "aws_iam_role" "isse" {
  name               = var.isse_role_name
  assume_role_policy = data.aws_iam_policy_document.user_assume_role_policy.json
}

locals {
  operator_roles = [
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AdministratorAccess",
  ]
}

resource "aws_iam_role_policy_attachment" "isse" {
  for_each = toset(local.operator_roles)

  role       = aws_iam_role.isse.name
  policy_arn = each.value
}

resource "aws_iam_group_policy_attachment" "isse" {
  for_each = toset(local.operator_roles)

  group      = "tws-isses"
  policy_arn = each.value
}

resource "aws_iam_policy_attachment" "isse" {
  for_each = toset([
    aws_iam_policy.isse.arn,
  ])

  name       = var.isse_role_name
  roles      = [aws_iam_role.isse.name]
  groups     = ["tws-isses"] // this group created manually and assigned to the ISSEs on the team
  policy_arn = each.value
}

data "aws_iam_policy_document" "fluentd" {
  statement {
    effect = "Allow"

    actions = [
      "logs:*",
      "s3:*",
      "sqs:*",
      "ec2:CreateTags",
      "ec2:DescribeTags",
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

data "aws_iam_policy_document" "loki" {
  statement {
    effect = "Allow"

    actions = [
      "s3:*",
      "ec2:CreateTags",
      "ec2:DescribeTags",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "loki" {
  name   = var.loki_role_name
  path   = "/"
  policy = data.aws_iam_policy_document.loki.json
}

resource "aws_iam_role" "loki" {
  name               = var.loki_role_name
  assume_role_policy = data.aws_iam_policy_document.role_policy.json
}

resource "aws_iam_policy_attachment" "loki" {
  name       = var.loki_role_name
  roles      = [aws_iam_role.loki.name]
  policy_arn = aws_iam_policy.loki.arn
}

resource "aws_iam_instance_profile" "loki" {
  name = var.loki_role_name
  role = aws_iam_role.loki.name
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

output "concourse_role_arn" {
  value = aws_iam_role.concourse.arn
}

output "sjb_role_arn" {
  value = aws_iam_role.sjb.arn
}

output "om_role_arn" {
  value = aws_iam_role.om.arn
}

output "bosh_role_arn" {
  value = aws_iam_role.bosh.arn
}

output "pas_bucket_role_arn" {
  value = aws_iam_role.bucket.arn
}

output "bootstrap_role_arn" {
  value = aws_iam_role.bootstrap.arn
}

output "foundation_role_arn" {
  value = aws_iam_role.foundation.arn
}

data "aws_iam_policy_document" "instance_tagger" {
  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListAllMyBuckets",
      "ec2:CreateTags",
      "ec2:DescribeTags",
      "s3:ListBucket",
      "s3:DeleteObject",
      "s3:GetBucketLocation"
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

data "aws_iam_policy_document" "om" {
  version = "2012-10-17"

  statement {
    sid = "OpsMgrInfrastructureIaasConfiguration"

    effect = "Allow"

    actions = [
      "ec2:DescribeKeypairs",
      "ec2:DescribeVpcs",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeAccountAttributes"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "OpsMgrInfrastructureDirectorConfiguration"

    effect = "Allow"

    actions = [
      "s3:*"
    ]

    resources = ["*"]
  }

  statement {
    sid = "OpsMgrInfrastructureAvailabilityZones"

    effect = "Allow"

    actions = [
      "ec2:DescribeAvailabilityZones"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "OpsMgrInfrastructureNetworks"

    effect = "Allow"

    actions = [
      "ec2:DescribeSubnets"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "DeployMicroBosh"

    effect = "Allow"

    actions = [
      "ec2:DescribeImages",
      "ec2:RunInstances",
      "ec2:DescribeInstances",
      "ec2:TerminateInstances",
      "ec2:RebootInstances",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "ec2:DescribeAddresses",
      "ec2:DisassociateAddress",
      "ec2:AssociateAddress",
      "ec2:CreateTags",
      "ec2:DescribeVolumes",
      "ec2:CreateVolume",
      "ec2:AttachVolume",
      "ec2:DeleteVolume",
      "ec2:DetachVolume",
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot",
      "ec2:DescribeSnapshots",
      "ec2:DescribeRegions"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "RequiredIfUsingHeavyStemcells"

    effect = "Allow"

    actions = [
      "ec2:RegisterImage",
      "ec2:DeregisterImage"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "RequiredIfEncryptingStemcells"

    effect = "Allow"

    actions = [
      "ec2:CopyImage"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "RequiredIfUsingCustomKMSKeys"

    effect = "Allow"

    actions = [
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey*"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "RequiredIfUsingLBTargetGroupCloudProperties"

    effect = "Allow"

    actions = [
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:RegisterTargets"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "RequiredIfUsingSpotBidPriceCloudProperties"

    effect = "Allow"

    actions = [
      "ec2:CancelSpotInstanceRequests",
      "ec2:DescribeSpotInstanceRequests",
      "ec2:RequestSpotInstances"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "RequiredIfUsingAdvertisedRoutesCloudProperties"

    effect = "Allow"

    actions = [
      "ec2:CreateRoute",
      "ec2:DescribeRouteTables",
      "ec2:ReplaceRoute"
    ]

    resources = [
      "*"
    ]
  }

  // -- Added to work with TWS --
  statement {
    sid    = "RequiredForTWS"
    effect = "Allow"
    actions = [
      "iam:GetInstanceProfile",
      "iam:PassRole"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "om" {
  name   = var.om_role_name
  path   = "/"
  policy = data.aws_iam_policy_document.om.json
}

resource "aws_iam_role" "om" {
  name               = var.om_role_name
  assume_role_policy = data.aws_iam_policy_document.role_policy.json
}

resource "aws_iam_policy_attachment" "om" {
  name = var.instance_tagger_role_name
  roles = [
    aws_iam_role.om.name
  ]
  policy_arn = aws_iam_policy.om.arn
}

resource "aws_iam_instance_profile" "om" {
  name = var.om_role_name
  role = aws_iam_role.om.name
}

data "aws_iam_policy_document" "bosh" {
  statement {
    sid = "BaselinePolicy"

    effect = "Allow"

    actions = [
      "ec2:AttachVolume",
      "ec2:CopyImage",
      "ec2:CopySnapshot",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:DeleteVolume",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVolumes",
      "ec2:DetachVolume",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:RegisterImage",
      "ec2:DeregisterImage",
      "s3:*",
    ]

    resources = [
    "*"]
  }



  statement {
    sid    = "RequiredIfUsingSnapshotsFeature"
    effect = "Allow"
    actions = [
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot",
    "ec2:DescribeSnapshots"]
    resources = [
    "*"]
  }

  statement {
    sid    = "RequiredIfUsingElasticIPs"
    effect = "Allow"
    actions = [
      "ec2:AssociateAddress",
      "ec2:DescribeAddresses"
    ]
    resources = [
    "*"]
  }

  statement {
    sid    = "RequiredIfUsingSourceDestCheckCloudProperties"
    effect = "Allow"
    actions = [
      "ec2:ModifyInstanceAttribute"
    ]
    resources = [
    "*"]
  }

  statement {
    sid    = "RequiredIfUsingELBCloudProperties"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:RegisterTargets"
    ]
    resources = [
    "*"]
  }

  statement {
    sid    = "RequiredIfUsingIAMInstanceProfileCloudProperty"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      "*"
    ]
  }

  // -- Added to work with TWS --
  statement {
    sid    = "RequiredForTWS"
    effect = "Allow"
    actions = [
      "iam:GetInstanceProfile",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "bosh" {
  name   = var.bosh_role_name
  path   = "/"
  policy = data.aws_iam_policy_document.bosh.json
}

resource "aws_iam_role" "bosh" {
  name               = var.bosh_role_name
  assume_role_policy = data.aws_iam_policy_document.role_policy.json
}

resource "aws_iam_policy_attachment" "bosh" {
  name = var.instance_tagger_role_name
  roles = [
    aws_iam_role.bosh.name
  ]
  policy_arn = aws_iam_policy.bosh.arn
}

resource "aws_iam_instance_profile" "bosh" {
  name = var.bosh_role_name
  role = aws_iam_role.bosh.name
}

// Policy document copied from Director
data "aws_iam_policy_document" "sjb" {
  statement {
    effect = "Allow"

    actions = [
      "iam:GetServerCertificate",
      "iam:GetInstanceProfile",
      "iam:GetRole",
      "iam:GetUser",
      "iam:GetPolicy",
      "s3:*",
      "sqs:*",
      "iam:ListServerCertificates",
      "iam:ListEntitiesForPolicy",
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
      "iam:DetachRolePolicy",
      "iam:AttachRolePolicy",
      "iam:ListRolePolicies",
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

resource "aws_iam_policy" "sjb" {
  name   = var.sjb_role_name
  path   = "/"
  policy = data.aws_iam_policy_document.sjb.json
}

resource "aws_iam_role" "sjb" {
  name               = var.sjb_role_name
  assume_role_policy = data.aws_iam_policy_document.role_policy.json
}

resource "aws_iam_policy_attachment" "sjb" {
  name       = var.sjb_role_name
  roles      = [aws_iam_role.sjb.name]
  policy_arn = aws_iam_policy.sjb.arn
}

resource "aws_iam_role_policy_attachment" "sjb_ecr" {
  role       = aws_iam_role.sjb.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_instance_profile" "sjb" {
  name = var.sjb_role_name
  role = aws_iam_role.sjb.name
}

// This policy document is copied from Director
data "aws_iam_policy_document" "concourse" {
  statement {
    effect = "Allow"

    actions = [
      "iam:GetServerCertificate",
      "iam:GetInstanceProfile",
      "iam:GetRole",
      "iam:GetUser",
      "iam:GetPolicy",
      "s3:*",
      "sqs:*",
      "iam:ListServerCertificates",
      "iam:ListEntitiesForPolicy",
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
      "iam:DetachRolePolicy",
      "iam:AttachRolePolicy",
      "iam:ListRolePolicies",
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

resource "aws_iam_policy" "concourse" {
  name   = var.concourse_role_name
  path   = "/"
  policy = data.aws_iam_policy_document.concourse.json
}

resource "aws_iam_role" "concourse" {
  name               = var.concourse_role_name
  assume_role_policy = data.aws_iam_policy_document.role_policy.json
}

resource "aws_iam_policy_attachment" "concourse" {
  name       = var.concourse_role_name
  roles      = [aws_iam_role.concourse.name]
  policy_arn = aws_iam_policy.concourse.arn
}

resource "aws_iam_role_policy_attachment" "concourse_ecr" {
  role       = aws_iam_role.concourse.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_instance_profile" "concourse" {
  name = var.concourse_role_name
  role = aws_iam_role.concourse.name
}

data "aws_iam_policy_document" "foundation" {
  statement {
    sid = "BoshBaselinePolicy"

    effect = "Allow"

    actions = [
      "ec2:AttachVolume",
      "ec2:CopyImage",
      "ec2:CopySnapshot",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:DeleteVolume",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVolumes",
      "ec2:DetachVolume",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:RegisterImage",
      "ec2:DeregisterImage",
      "s3:*",
    ]

    resources = [
    "*"]
  }

  statement {
    sid = "OpsMgrInfrastructureIaasConfiguration"

    effect = "Allow"

    actions = [
      "ec2:DescribeKeypairs",
      "ec2:DescribeVpcs",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeAccountAttributes"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "DeployMicroBosh"

    effect = "Allow"

    actions = [
      "ec2:RebootInstances",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "ec2:DisassociateAddress"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid    = "RequiredIfUsingElasticIPs"
    effect = "Allow"
    actions = [
      "ec2:AssociateAddress",
      "ec2:DescribeAddresses"
    ]
    resources = [
    "*"]
  }

  statement {
    sid    = "RequiredIfUsingSnapshotsFeature"
    effect = "Allow"
    actions = [
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot",
      "ec2:DescribeSnapshots"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "RequiredIfUsingCustomKMSKeys"

    effect = "Allow"

    actions = [
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey*"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "RequiredIfUsingSpotBidPriceCloudProperties"

    effect = "Allow"

    actions = [
      "ec2:CancelSpotInstanceRequests",
      "ec2:DescribeSpotInstanceRequests",
      "ec2:RequestSpotInstances"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "RequiredIfUsingAdvertisedRoutesCloudProperties"

    effect = "Allow"

    actions = [
      "ec2:CreateRoute",
      "ec2:DescribeRouteTables",
      "ec2:ReplaceRoute"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid    = "RequiredIfUsingSourceDestCheckCloudProperties"
    effect = "Allow"
    actions = [
      "ec2:ModifyInstanceAttribute"
    ]
    resources = [
    "*"]
  }

  statement {
    sid = "RequiredIfUsingLBTargetGroupCloudPropertiesOrELBCloudProperties"

    effect = "Allow"

    actions = [
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:RegisterTargets"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid    = "RequiredIfUsingIAMInstanceProfileCloudProperty"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "RequiredForTWS"
    effect = "Allow"
    actions = [
      "iam:GetInstanceProfile"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "foundation" {
  name   = var.foundation_role_name
  path   = "/"
  policy = data.aws_iam_policy_document.foundation.json
}

resource "aws_iam_role" "foundation" {
  name               = var.foundation_role_name
  assume_role_policy = data.aws_iam_policy_document.role_policy.json
}

resource "aws_iam_policy_attachment" "foundation" {
  name = var.instance_tagger_role_name
  roles = [
    aws_iam_role.foundation.name
  ]
  policy_arn = aws_iam_policy.foundation.arn
}

resource "aws_iam_instance_profile" "foundation" {
  name = var.foundation_role_name
  role = aws_iam_role.foundation.name
}
