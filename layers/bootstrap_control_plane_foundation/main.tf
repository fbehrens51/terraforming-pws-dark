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

data "aws_vpc" "vpc" {
  id = data.terraform_remote_state.paperwork.outputs.cp_vpc_id
}
data "aws_vpc" "pas_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
}

locals {
  secrets_bucket_name = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
  s3_logs_bucket      = data.terraform_remote_state.paperwork.outputs.s3_logs_bucket
  bucket_suffix_name  = "cp"
  env_name            = var.global_vars.env_name
  modified_name       = "${local.env_name} control plane"
  modified_tags = merge(
    var.global_vars["global_tags"],
    {
      "Name"            = local.modified_name
      "MetricsKey"      = data.terraform_remote_state.paperwork.outputs.metrics_key,
      "foundation_name" = data.terraform_remote_state.paperwork.outputs.foundation_name
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

  default_cp_sg_id     = data.terraform_remote_state.bootstrap_control_plane.outputs.vms_security_group_id
  transfer_kms_key_arn = data.terraform_remote_state.paperwork.outputs.transfer_key_arn
}

module "ops_manager" {
  source = "../../modules/ops_manager/infra"

  bucket_suffix_name    = local.bucket_suffix_name
  env_name              = local.env_name
  om_eip                = !var.internetless
  private               = false
  subnet_id             = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_public_subnet_ids[0]
  tags                  = local.modified_tags
  vpc_id                = data.aws_vpc.vpc.id
  ingress_rules         = local.om_ingress_rules
  s3_logs_bucket        = local.s3_logs_bucket
  force_destroy_buckets = var.force_destroy_buckets
  operating_system      = data.terraform_remote_state.paperwork.outputs.ubuntu_operating_system_tag
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

module "transfer_bucket_policy" {
  source     = "../../modules/bucket/policy/default_tls"
  bucket_arn = aws_s3_bucket.transfer_bucket.arn
}

resource "aws_s3_bucket_policy" "transfer_bucket_policy_attachment" {
  bucket = aws_s3_bucket.transfer_bucket.bucket
  policy = module.transfer_bucket_policy.json
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

module "import_bucket_policy" {
  source     = "../../modules/bucket/policy/default_tls"
  bucket_arn = aws_s3_bucket.import_bucket.arn
}

resource "aws_s3_bucket_policy" "import_bucket_policy_attachment" {
  bucket = aws_s3_bucket.import_bucket.bucket
  policy = module.import_bucket_policy.json
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

module "mirror_bucket_policy" {
  source     = "../../modules/bucket/policy/default_tls"
  bucket_arn = aws_s3_bucket.mirror_bucket.arn
}

resource "aws_s3_bucket_policy" "mirror_bucket_policy_attachment" {
  bucket = aws_s3_bucket.mirror_bucket.bucket
  policy = module.mirror_bucket_policy.json
}

module "postgres" {
  source = "../../modules/rds/instance"

  rds_db_username    = var.rds_db_username
  rds_instance_class = var.rds_instance_class

  engine         = var.concourse_db_engine
  engine_version = var.concourse_db_engine_version

  db_port      = 5432
  sg_rule_desc = "postgres/5432"

  env_name = local.modified_name
  vpc_id   = data.aws_vpc.vpc.id
  tags     = local.modified_tags

  subnet_group_name = module.rds_subnet_group.subnet_group_name

  kms_key_id = data.terraform_remote_state.paperwork.outputs.kms_key_arn

  #Disable apply_immediately for concourse postgres RDS.  We don't want the DB to be upgraded while concourse is running a deployment (Concourse uses it for job logs, pipelines, etc)
  apply_immediately  = false
  maintenance_window = var.concourse_postgres_maintenance_window
  backup_window      = var.concourse_postgres_backup_window

  database_deletion_protection = var.database_deletion_protection
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

  database_deletion_protection = var.database_deletion_protection
}

module "rds_subnet_group" {
  source = "../../modules/rds/subnet_group"

  env_name           = local.modified_name
  availability_zones = slice(var.availability_zones, 0, 2)
  vpc_id             = data.aws_vpc.vpc.id
  cidr_block         = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_rds_cidr_block
  tags               = local.modified_tags
}

# NLBs

module "concourse_nlb" {
  source                     = "./modules/nlb/create"
  env_name                   = local.env_name
  internetless               = var.internetless
  public_subnet_ids          = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_public_subnet_ids
  tags                       = var.global_vars["global_tags"]
  vpc_id                     = data.aws_vpc.vpc.id
  metrics_ingress_cidr_block = data.aws_vpc.pas_vpc.cidr_block
  egress_cidrs               = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_private_subnet_cidrs
  health_check_cidr_blocks   = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_public_cidrs
}

module "uaa_nlb" {
  source            = "../../modules/nlb/create"
  env_name          = local.env_name
  internetless      = var.internetless
  public_subnet_ids = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_public_subnet_ids
  tags              = var.global_vars["global_tags"]
  vpc_id            = data.aws_vpc.vpc.id
  egress_cidrs      = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_private_subnet_cidrs
  #  preserve_client_ip       = false
  short_name               = "uaa"
  port                     = 8443
  health_check_port        = 8443
  health_check_proto       = "HTTPS"
  health_check_path        = "/healthz"
  health_check_cidr_blocks = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_public_cidrs
}

module "credhub_nlb" {
  source                   = "../../modules/nlb/create"
  env_name                 = local.env_name
  internetless             = var.internetless
  public_subnet_ids        = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_public_subnet_ids
  tags                     = var.global_vars["global_tags"]
  vpc_id                   = data.aws_vpc.vpc.id
  egress_cidrs             = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_private_subnet_cidrs
  short_name               = "credhub"
  port                     = 8844
  health_check_port        = 8845
  health_check_proto       = "HTTP"
  health_check_path        = "/health"
  health_check_cidr_blocks = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_public_cidrs
}

# ELBs

locals {

  uaa_listener_to_instance_ports = [{
    port                = 8443
    instance_port       = 8443
    enable_proxy_policy = false
  }]

  credhub_listener_to_instance_ports = [{
    port                = 8844
    instance_port       = 8844
    enable_proxy_policy = false
  }]

}

module "uaa_elb" {
  source                     = "../../modules/elb/create"
  env_name                   = local.env_name
  internetless               = var.internetless
  public_subnet_ids          = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_public_subnet_ids
  tags                       = var.global_vars["global_tags"]
  vpc_id                     = data.aws_vpc.vpc.id
  egress_cidrs               = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_private_subnet_cidrs
  short_name                 = "uaa"
  health_check               = "HTTPS:8443/healthz"
  listener_to_instance_ports = local.uaa_listener_to_instance_ports
}

module "credhub_elb" {
  source                     = "../../modules/elb/create"
  env_name                   = local.env_name
  internetless               = var.internetless
  public_subnet_ids          = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_public_subnet_ids
  tags                       = var.global_vars["global_tags"]
  vpc_id                     = data.aws_vpc.vpc.id
  egress_cidrs               = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_private_subnet_cidrs
  short_name                 = "credhub"
  health_check               = "HTTP:8845/health"
  listener_to_instance_ports = local.credhub_listener_to_instance_ports
}

resource "aws_security_group_rule" "credhub_ingress_health_rule" {
  description       = "Allow tcp/8845 from anywhere"
  from_port         = 8845
  to_port           = 8845
  protocol          = "TCP"
  type              = "ingress"
  security_group_id = module.credhub_elb.security_group_id
  cidr_blocks       = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_public_cidrs
}

module "om_key_pair" {
  source   = "../../modules/key_pair"
  key_name = local.om_key_name
}

resource "aws_s3_bucket_object" "mysql-rds-password" {
  bucket       = local.secrets_bucket_name
  content_type = "text/plain"
  key          = "control_plane/mysql-rds-password"
  content      = module.mysql.rds_password
}

resource "aws_s3_bucket_object" "postgres-rds-password" {
  bucket       = local.secrets_bucket_name
  content_type = "text/plain"
  key          = "control_plane/postgres-rds-password"
  content      = module.postgres.rds_password
}
