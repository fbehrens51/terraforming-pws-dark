variable "director_role_name" {}

variable "bucket_role_name" {}

data "aws_iam_policy_document" "director" {
  statement {
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:GetServerCertificate",
      "iam:GetInstanceProfile",
      "dynamodb:ListTables",
      "s3:*",
      "iam:ListServerCertificates",
      "elasticloadbalancing:*",
      "rds:DescribeEngineDefaultParameters",
      "rds:PurchaseReservedDBInstancesOffering",
      "iam:UploadServerCertificate",
      "elasticloadbalancing:DescribeLoadBalancers",
      "iam:PassRole",
      "rds:DescribeDBClusterSnapshots",
      "kms:ListAliases",
      "rds:DescribeEngineDefaultClusterParameters",
      "rds:DescribeDBInstances",
      "rds:DescribeOrderableDBInstanceOptions",
      "iam:DeleteServerCertificate",
      "ec2:*",
      "elasticache:*",
      "kms:DescribeKey",
      "rds:DownloadCompleteDBLogFile",
      "rds:DescribeCertificates",
      "rds:DescribeEventCategories",
      "rds:DescribeAccountAttributes"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:GetItem"
    ]
    resources = ["arn:aws:dynamodb:us-east-1:623687983927:table/state_lock"]
  }

  statement {
    effect = "Allow"
    actions = ["rds:*"]
    resources = [
      "arn:aws:rds:*:*:snapshot:*",
      "arn:aws:rds:*:*:db:*",
      "arn:aws:rds:*:*:secgrp:*",
      "arn:aws:rds:*:*:cluster:*",
      "arn:aws:rds:*:*:subgrp:*",
      "arn:aws:rds:*:*:og:*",
      "arn:aws:rds:*:*:ri:*",
      "arn:aws:rds:*:*:cluster-snapshot:*",
      "arn:aws:rds:*:*:pg:*",
      "arn:aws:iam::*:role/*",
      "arn:aws:rds:*:*:es:*"
    ]
  }

  statement {
    effect = "Allow"
    actions = ["rds:*"]
    resources = [
      "arn:aws:s3:::bosh-blobstore/*",
      "arn:aws:s3:::pws-dark-runtime-blobstore/*",
      "arn:aws:s3:::bosh-blobstore",
      "arn:aws:s3:::pws-dark-runtime-blobstore"]
  }

  statement {
    effect = "Allow"
    actions = ["rds:*"]
    resources = ["arn:aws:rds:*:*:cluster-snapshot:*"]
  }
}

data "aws_iam_policy_document" "bucket" {
  statement {
    effect = "Allow"
    actions = ["s3:*"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "role_policy" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["ec2.amazonaws.com"]
      type = "Service"
    }
  }
}

resource "aws_iam_policy" "director" {
  name = "${var.director_role_name}"
  path = "/"
  policy = "${data.aws_iam_policy_document.director.json}"
}

resource "aws_iam_role" "director" {
  name = "${var.director_role_name}"
  assume_role_policy = "${data.aws_iam_policy_document.role_policy.json}"
}

resource "aws_iam_policy_attachment" "director" {
  name = "${var.director_role_name}"
  roles = ["${aws_iam_role.director.name}"]
  policy_arn = "${aws_iam_policy.director.arn}"
}

resource "aws_iam_instance_profile" "director" {
  name = "${var.director_role_name}"
  role = "${aws_iam_role.director.name}"
}

resource "aws_iam_policy" "bucket" {
  name = "${var.bucket_role_name}"
  path = "/"
  policy = "${data.aws_iam_policy_document.bucket.json}"
}

resource "aws_iam_role" "bucket" {
  name = "${var.bucket_role_name}"
  assume_role_policy = "${data.aws_iam_policy_document.role_policy.json}"
}

resource "aws_iam_policy_attachment" "bucket" {
  name = "${var.bucket_role_name}"
  roles = ["${aws_iam_role.bucket.name}"]
  policy_arn = "${aws_iam_policy.bucket.arn}"
}

output "director_role_id" {
  value = "${aws_iam_role.director.id}"
}

output "bucket_role_id" {
  value = "${aws_iam_role.bucket.id}"
}

output "bucket_role_arn" {
  value = "${aws_iam_role.bucket.arn}"
}
