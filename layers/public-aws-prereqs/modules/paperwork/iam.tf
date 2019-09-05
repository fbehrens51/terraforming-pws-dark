variable "director_role_name" {}

variable "bucket_role_name" {}

variable "worker_role_name" {}

variable "splunk_role_name" {}

variable "key_manager_role_name" {}

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

data "aws_caller_identity" "myself" {}

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
  name   = "${var.director_role_name}"
  path   = "/"
  policy = "${data.aws_iam_policy_document.director.json}"
}

resource "aws_iam_role" "director" {
  name               = "${var.director_role_name}"
  assume_role_policy = "${data.aws_iam_policy_document.role_policy.json}"
}

resource "aws_iam_policy_attachment" "director" {
  name       = "${var.director_role_name}"
  roles      = ["${aws_iam_role.director.name}"]
  policy_arn = "${aws_iam_policy.director.arn}"
}

resource "aws_iam_instance_profile" "director" {
  name = "${var.director_role_name}"
  role = "${aws_iam_role.director.name}"
}

resource "aws_iam_instance_profile" "worker" {
  name = "${var.worker_role_name}"
  role = "${aws_iam_role.bucket.name}"
}

resource "aws_iam_instance_profile" "bucket" {
  name = "${var.bucket_role_name}"
  role = "${aws_iam_role.bucket.name}"
}

resource "aws_iam_policy" "bucket" {
  name   = "${var.bucket_role_name}"
  path   = "/"
  policy = "${data.aws_iam_policy_document.bucket.json}"
}

resource "aws_iam_role" "bucket" {
  name               = "${var.bucket_role_name}"
  assume_role_policy = "${data.aws_iam_policy_document.role_policy.json}"
}

resource "aws_iam_policy_attachment" "bucket" {
  name       = "${var.bucket_role_name}"
  roles      = ["${aws_iam_role.bucket.name}"]
  policy_arn = "${aws_iam_policy.bucket.arn}"
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

resource "aws_iam_policy" "kms_admin_user" {
  # The following canned policy doesn't allow changing the key policy

  # arn = "arn:aws:iam::aws:policy/AWSKeyManagementServicePowerUser"

  name   = "${var.key_manager_role_name}"
  policy = "${data.aws_iam_policy_document.kms_admin_user.json}"
}

resource "aws_iam_role" "key_manager" {
  name               = "${var.key_manager_role_name}"
  assume_role_policy = "${data.aws_iam_policy_document.user_assume_role_policy.json}"
}

resource "aws_iam_role_policy_attachment" "key_manager_attach" {
  policy_arn = "${aws_iam_policy.kms_admin_user.arn}"
  role       = "${aws_iam_role.key_manager.name}"
}

data "aws_iam_policy_document" "s3_reader" {
  statement {
    effect = "Allow"

    actions = ["s3:Get*",
      "s3:List*",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy_attachment" "splunk" {
  name       = "${var.splunk_role_name}"
  roles      = ["${aws_iam_role.splunk_role.name}"]
  policy_arn = "${aws_iam_policy.splunk_reader.arn}"
}

resource "aws_iam_policy" "splunk_reader" {
  name   = "${var.splunk_role_name}"
  path   = "/"
  policy = "${data.aws_iam_policy_document.s3_reader.json}"
}

resource "aws_iam_role" "splunk_role" {
  name               = "${var.splunk_role_name}"
  assume_role_policy = "${data.aws_iam_policy_document.role_policy.json}"
}

resource "aws_iam_instance_profile" "splunk_instance_profile" {
  name = "${aws_iam_role.splunk_role.name}"
  role = "${aws_iam_role.splunk_role.name}"
}

output "director_role_arn" {
  value = "${aws_iam_role.director.arn}"
}

output "pas_bucket_role_arn" {
  value = "${aws_iam_role.bucket.arn}"
}
