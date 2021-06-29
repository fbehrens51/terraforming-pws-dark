provider "aws" {
}

module "providers" {
  source = "../../modules/dark_providers"
}

terraform {
  backend "s3" {
  }
}

data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "paperwork"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "scaling-params" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "scaling-params"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_control_plane" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_control_plane"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "routes" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "routes"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "aws_vpc" "vpc" {
  id = data.terraform_remote_state.paperwork.outputs.cp_vpc_id
}
data "aws_vpc" "pas_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
}

locals {
  s3_logs_bucket     = data.terraform_remote_state.paperwork.outputs.s3_logs_bucket
  bucket_suffix_name = "cp"
  env_name           = var.global_vars.env_name
  modified_name      = "${local.env_name} control plane"
  modified_tags = merge(
    var.global_vars["global_tags"],
    {
      "Name"       = local.modified_name
      "MetricsKey" = data.terraform_remote_state.paperwork.outputs.metrics_key,
    },
  )

  bucket_prefix        = replace(local.env_name, " ", "-")
  import_bucket_name   = "${local.bucket_prefix}-import"
  transfer_bucket_name = "${local.bucket_prefix}-transfer"
  mirror_bucket_name   = "${local.bucket_prefix}-mirror"

  om_key_name = "${local.env_name}-cp-om"

  om_ingress_rules = [
    {
      description = "Allow ssh/22 from cp_vpc"
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = data.aws_vpc.vpc.cidr_block
    },
    {
      description = "Allow https/443 from everywhere"
      port        = "443"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      description = "Allow node_exporter/9100 from pas_vpc"
      port        = "9100"
      protocol    = "tcp"
      cidr_blocks = data.aws_vpc.pas_vpc.cidr_block
    },
  ]

  transfer_kms_key_arn = data.terraform_remote_state.paperwork.outputs.transfer_key_arn

}

module "ops_manager" {
  source = "../../modules/ops_manager/infra"

  bucket_suffix_name    = local.bucket_suffix_name
  env_name              = local.env_name
  om_eip                = ! var.internetless
  private               = false
  subnet_id             = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_public_subnet_ids[0]
  tags                  = local.modified_tags
  vpc_id                = data.aws_vpc.vpc.id
  ingress_rules         = local.om_ingress_rules
  s3_logs_bucket        = local.s3_logs_bucket
  force_destroy_buckets = var.force_destroy_buckets
}

resource "aws_s3_bucket" "import_bucket" {
  bucket        = local.import_bucket_name
  force_destroy = var.force_destroy_buckets

  //use account's default S3 encryption key
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  logging {
    target_bucket = local.s3_logs_bucket
    target_prefix = "${local.import_bucket_name}/"
  }

  tags = merge(
    var.global_vars["global_tags"],
    {
      "Name" = "${local.env_name} Import Bucket"
    },
  )
}


resource "aws_s3_bucket" "transfer_bucket" {
  bucket        = local.transfer_bucket_name
  force_destroy = var.force_destroy_buckets
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = local.transfer_kms_key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  logging {
    target_bucket = local.s3_logs_bucket
    target_prefix = "${local.transfer_bucket_name}/"
  }


  tags = merge(
    var.global_vars["global_tags"],
    {
      "Name" = "${local.env_name} Transfer Bucket"
    },
  )
}


data "aws_iam_policy_document" "transfer_bucket_policy" {
  statement {
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:ListBucket", "s3:PutObject", "s3:PutObjectAcl"]

    principals {
      type        = "AWS"
      identifiers = [var.promoter_role_arn]
    }

    resources = [aws_s3_bucket.transfer_bucket.arn, "${aws_s3_bucket.transfer_bucket.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "transfer_bucket_policy_attachement" {
  bucket = aws_s3_bucket.transfer_bucket.bucket
  policy = data.aws_iam_policy_document.transfer_bucket_policy.json
}


resource "aws_s3_bucket" "mirror_bucket" {
  bucket        = local.mirror_bucket_name
  force_destroy = var.force_destroy_buckets

  //use account's default S3 encryption key
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  logging {
    target_bucket = local.s3_logs_bucket
    target_prefix = "${local.mirror_bucket_name}/"
  }

  tags = merge(
    var.global_vars["global_tags"],
    {
      "Name" = "${local.env_name} Mirror Bucket"
    },
  )
}

module "postgres" {
  source = "../../modules/rds/instance"

  rds_db_username    = var.rds_db_username
  rds_instance_class = var.rds_instance_class

  engine = "postgres"

  # RDS decided to upgrade the mysql patch version automatically from 10.1.31 to
  # 10.1.34, which makes terraform see this as a change. Use a prefix version to
  # prevent this from happening with postgres.
  engine_version = "9.6"

  db_port      = 5432
  sg_rule_desc = "postgres/5432"

  env_name = local.modified_name
  vpc_id   = data.aws_vpc.vpc.id
  tags     = local.modified_tags

  subnet_group_name = module.rds_subnet_group.subnet_group_name

  kms_key_id = data.terraform_remote_state.paperwork.outputs.kms_key_arn
}

module "mysql" {
  source = "../../modules/rds/instance"

  rds_db_username    = var.rds_db_username
  rds_instance_class = var.rds_instance_class

  engine = var.control_plane_db_engine

  # RDS decided to upgrade the mysql patch version automatically from 10.1.31 to
  # 10.1.34, which makes terraform see this as a change. Use a prefix version to
  # prevent this from happening with postgres.
  engine_version = var.control_plane_db_engine_version

  db_port      = 3306
  sg_rule_desc = "mysql/3306"

  env_name = "${local.modified_name} mysql"
  vpc_id   = data.aws_vpc.vpc.id
  tags     = local.modified_tags

  subnet_group_name = module.rds_subnet_group.subnet_group_name

  kms_key_id = data.terraform_remote_state.paperwork.outputs.kms_key_arn
}

module "rds_subnet_group" {
  source = "../../modules/rds/subnet_group"

  env_name           = local.modified_name
  availability_zones = slice(var.availability_zones, 0, 2)
  vpc_id             = data.aws_vpc.vpc.id
  cidr_block         = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_rds_cidr_block
  tags               = local.modified_tags
}

module "concourse_nlb" {
  source                     = "./modules/nlb/create"
  env_name                   = local.env_name
  internetless               = var.internetless
  public_subnet_ids          = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_public_subnet_ids
  tags                       = var.global_vars["global_tags"]
  vpc_id                     = data.aws_vpc.vpc.id
  metrics_ingress_cidr_block = data.aws_vpc.pas_vpc.cidr_block
  egress_cidrs               = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_private_subnet_cidrs
}

module "uaa_elb" {
  source            = "../../modules/elb/create"
  env_name          = local.env_name
  internetless      = var.internetless
  public_subnet_ids = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_public_subnet_ids
  tags              = var.global_vars["global_tags"]
  vpc_id            = data.aws_vpc.vpc.id
  egress_cidrs      = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_private_subnet_cidrs
  short_name        = "uaa"
  port              = 8443
}

module "credhub_elb" {
  source            = "../../modules/elb/create"
  env_name          = local.env_name
  internetless      = var.internetless
  public_subnet_ids = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_public_subnet_ids
  tags              = var.global_vars["global_tags"]
  vpc_id            = data.aws_vpc.vpc.id
  egress_cidrs      = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_private_subnet_cidrs
  short_name        = "credhub"
  port              = 8844
  health_check      = "TCP:8844"
}

module "om_key_pair" {
  source   = "../../modules/key_pair"
  key_name = local.om_key_name
}
