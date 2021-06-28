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

module "ops_manager" {
  source = "../../modules/ops_manager/infra"

  bucket_suffix_name    = local.bucket_suffix_name
  env_name              = local.env_name
  om_eip                = ! var.internetless
  private               = false
  subnet_id             = module.public_subnets.subnet_ids[0]
  tags                  = local.modified_tags
  vpc_id                = local.vpc_id
  ingress_rules         = local.om_ingress_rules
  s3_logs_bucket        = local.s3_logs_bucket
  force_destroy_buckets = var.force_destroy_buckets
}

module "public_subnets" {
  source             = "../../modules/subnet_per_az"
  availability_zones = var.availability_zones
  vpc_id             = data.aws_vpc.vpc.id
  cidr_block         = local.public_cidr_block
  tags = merge(
    local.modified_tags,
    {
      "Name" = "${local.modified_name}-public"
    },
  )
}

resource "aws_route_table_association" "public_route_table_assoc" {
  count          = length(var.availability_zones)
  subnet_id      = module.public_subnets.subnet_ids[count.index]
  route_table_id = data.terraform_remote_state.routes.outputs.cp_public_vpc_route_table_id
}

module "private_subnets" {
  source             = "../../modules/subnet_per_az"
  availability_zones = var.availability_zones
  vpc_id             = data.aws_vpc.vpc.id
  cidr_block         = local.private_cidr_block
  tags = merge(
    local.modified_tags,
    {
      "Name" = "${local.modified_name}-private"
    },
  )
}

resource "aws_route_table_association" "private_route_table_assoc" {
  count          = length(var.availability_zones)
  subnet_id      = module.private_subnets.subnet_ids[count.index]
  route_table_id = data.terraform_remote_state.routes.outputs.cp_private_vpc_route_table_ids[count.index]
}

module "om_key_pair" {
  source   = "../../modules/key_pair"
  key_name = local.om_key_name
}

resource "aws_security_group" "vms_security_group" {
  count = 1

  name        = "vms_security_group"
  description = "VMs Security Group"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    description = "Allow all traffic from within the control plane"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  egress {
    description = "Allow all portocols/ports to everywhere"
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  tags = merge(
    local.modified_tags,
    {
      Name        = "${local.env_name}-vms-security-group"
      Description = "bootstrap_control_plane"
    },
  )
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

data "template_cloudinit_config" "nat_user_data" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "clamav.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.amazon2_clamav_user_data
  }

  part {
    filename     = "node_exporter.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.node_exporter_user_data
  }

  part {
    filename     = "banner.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.custom_banner_user_data
  }

  part {
    filename     = "hardening.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.server_hardening_user_data
  }

  part {
    filename     = "bot_user_accounts_user_data.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.bot_user_accounts_user_data
  }

  part {
    filename     = "tag_completion.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.completion_tag_user_data
  }

  part {
    filename     = "iptables.cfg"
    content_type = "text/cloud-config"
    content      = module.iptables_rules.iptables_user_data
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }
}

module "iptables_rules" {
  source                     = "../../modules/iptables"
  nat                        = true
  control_plane_subnet_cidrs = [data.aws_vpc.vpc.cidr_block]
}

module "nat" {
  source                     = "../../modules/nat"
  ami_id                     = data.terraform_remote_state.paperwork.outputs.amzn_ami_id
  private_route_table_ids    = data.terraform_remote_state.routes.outputs.cp_private_vpc_route_table_ids
  ingress_cidr_blocks        = [data.aws_vpc.vpc.cidr_block]
  metrics_ingress_cidr_block = data.aws_vpc.pas_vpc.cidr_block
  tags                       = { tags = local.modified_tags, instance_tags = var.global_vars["instance_tags"] }
  public_subnet_ids          = module.public_subnets.subnet_ids
  internetless               = var.internetless
  ssh_cidr_blocks            = [local.private_cidr_block]
  bot_key_pem                = data.terraform_remote_state.paperwork.outputs.bot_private_key
  instance_types             = data.terraform_remote_state.scaling-params.outputs.instance_types
  scale_vpc_key              = "control-plane"
  user_data                  = data.template_cloudinit_config.nat_user_data.rendered
  root_domain                = data.terraform_remote_state.paperwork.outputs.root_domain
  syslog_ca_cert             = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs
  check_cloud_init           = data.terraform_remote_state.paperwork.outputs.check_cloud_init == "false" ? false : true

  public_bucket_name = data.terraform_remote_state.paperwork.outputs.public_bucket_name
  public_bucket_url  = data.terraform_remote_state.paperwork.outputs.public_bucket_url

  role_name = data.terraform_remote_state.paperwork.outputs.instance_tagger_role_name
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
  cidr_block         = local.rds_cidr_block
  tags               = local.modified_tags
}

module "concourse_nlb" {
  source                     = "./modules/nlb/create"
  env_name                   = local.env_name
  internetless               = var.internetless
  public_subnet_ids          = module.public_subnets.subnet_ids
  tags                       = var.global_vars["global_tags"]
  vpc_id                     = local.vpc_id
  metrics_ingress_cidr_block = data.aws_vpc.pas_vpc.cidr_block
  egress_cidrs               = module.private_subnets.subnet_cidr_blocks
}

module "uaa_elb" {
  source            = "../../modules/elb/create"
  env_name          = local.env_name
  internetless      = var.internetless
  public_subnet_ids = module.public_subnets.subnet_ids
  tags              = var.global_vars["global_tags"]
  vpc_id            = local.vpc_id
  egress_cidrs      = module.private_subnets.subnet_cidr_blocks
  short_name        = "uaa"
  port              = 8443
}

module "credhub_elb" {
  source            = "../../modules/elb/create"
  env_name          = local.env_name
  internetless      = var.internetless
  public_subnet_ids = module.public_subnets.subnet_ids
  tags              = var.global_vars["global_tags"]
  vpc_id            = local.vpc_id
  egress_cidrs      = module.private_subnets.subnet_cidr_blocks
  short_name        = "credhub"
  port              = 8844
  health_check      = "TCP:8844"
}
resource "random_integer" "bucket" {
  min = 1
  max = 100000
}

resource "random_string" "credhub_client_secret" {
  length  = "32"
  special = false
}

data "aws_vpc" "bastion_vpc" {
  id = local.bastion_vpc_id
}

data "aws_vpc" "pas_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
}

data "aws_region" "current" {
}

locals {
  bastion_vpc_id     = data.terraform_remote_state.paperwork.outputs.bastion_vpc_id
  vpc_id             = data.terraform_remote_state.paperwork.outputs.cp_vpc_id
  s3_logs_bucket     = data.terraform_remote_state.paperwork.outputs.s3_logs_bucket
  bucket_suffix_name = "cp"
  om_key_name        = "${local.env_name}-cp-om"
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

  public_cidr_block  = cidrsubnet(data.aws_vpc.vpc.cidr_block, 1, 0)
  rds_cidr_block     = cidrsubnet(local.public_cidr_block, 2, 3)
  private_cidr_block = cidrsubnet(data.aws_vpc.vpc.cidr_block, 1, 1)
  sjb_cidr_block     = cidrsubnet(local.private_cidr_block, 2, 3)

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
  ec2_service_name = "${var.vpce_interface_prefix}${data.aws_region.current.name}.ec2"

  director_role_name   = data.terraform_remote_state.paperwork.outputs.director_role_name
  transfer_kms_key_arn = data.terraform_remote_state.paperwork.outputs.transfer_key_arn

  sjb_ingress_rules = concat(var.sjb_ingress_rules,
    [
      {
        // metrics endpoint for grafana
        description = "Allow grafana_metrics/9100 from pas_vpc"
        port        = "9100"
        protocol    = "tcp"
        cidr_blocks = data.aws_vpc.pas_vpc.cidr_block
      },
      {
        description = "Allow ssh from bastion"
        port        = "22"
        protocol    = "tcp"
        cidr_blocks = data.aws_vpc.bastion_vpc.cidr_block
      },
    ]
  )
}

module "sjb_subnet" {
  source             = "../../modules/subnet_per_az"
  availability_zones = [var.singleton_availability_zone]
  vpc_id             = data.aws_vpc.vpc.id
  cidr_block         = local.sjb_cidr_block
  tags = merge(
    local.modified_tags,
    {
      "Name" = "${local.modified_name}-sjb"
    },
  )
}

resource "aws_route_table_association" "sjb_route_table_assoc" {
  count          = "1"
  subnet_id      = module.sjb_subnet.subnet_ids[count.index]
  route_table_id = data.terraform_remote_state.routes.outputs.cp_private_vpc_route_table_ids[count.index]
}

module "sjb_bootstrap" {
  source        = "../../modules/eni_per_subnet"
  ingress_rules = local.sjb_ingress_rules
  egress_rules  = var.sjb_egress_rules
  subnet_ids    = module.sjb_subnet.subnet_ids
  eni_count     = "1"
  create_eip    = "false"
  tags          = local.modified_tags
}

resource "aws_vpc_endpoint" "cp_ec2" {
  vpc_id              = data.aws_vpc.vpc.id
  service_name        = local.ec2_service_name
  vpc_endpoint_type   = "Interface"
  security_group_ids  = aws_security_group.vms_security_group.*.id
  subnet_ids          = module.private_subnets.subnet_ids
  private_dns_enabled = true
  tags                = local.modified_tags
}

