terraform {
  backend "s3" {
  }
}

data "terraform_remote_state" "enterprise-services" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "enterprise-services"
    region  = var.remote_state_region
    encrypt = true
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

data "aws_vpc" "pas_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
}

module "syslog_ports" {
  source = "../../modules/syslog_ports"
}

locals {
  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} fluentd"
  modified_tags = merge(
    var.global_vars["global_tags"],
    {
      "Name" = local.modified_name
    },
  )

  subnets = data.terraform_remote_state.enterprise-services.outputs.private_subnet_ids

  public_subnet = data.terraform_remote_state.enterprise-services.outputs.public_subnet_ids[0]

  fluentd_ingress_rules = [
    {
      description = "Allow ssh/22 from everywhere"
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      description = "Allow syslog/${module.syslog_ports.syslog_port} from everywhere"
      port        = module.syslog_ports.syslog_port
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      description = "Allow syslog/${module.syslog_ports.apps_syslog_port} from everywhere"
      port        = module.syslog_ports.apps_syslog_port
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      // node_exporter metrics endpoint for grafana
      description = "Allow node_exporter/9100 from pas_vpc"
      port        = "9100"
      protocol    = "tcp"
      cidr_blocks = data.aws_vpc.pas_vpc.cidr_block
    },
    {
      // fluentd metrics endpoint for grafana
      description = "Allow fluentd_metrics/9200 from pas_vpc"
      port        = "9200"
      protocol    = "tcp"
      cidr_blocks = data.aws_vpc.pas_vpc.cidr_block
    },
    {
      // fluentd healthcheck endpoint
      description = "Allow healthcheck from ELBs"
      port        = "8888"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  fluentd_egress_rules = [
    {
      description = "Allow all protocols/ports to everywhere"
      port        = "0"
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  private_subnets = data.terraform_remote_state.enterprise-services.outputs.private_subnet_ids

  formatted_env_name = replace(local.env_name, " ", "-")

  audit_log_group_name = "${replace(local.env_name, " ", "_")}_audit_log_group"
  log_group_name       = "${replace(local.env_name, " ", "_")}_log_group"

  s3_logs_bucket = data.terraform_remote_state.paperwork.outputs.s3_logs_bucket

  syslog_archive_bucket       = "${local.formatted_env_name}-syslog-archive"
  syslog_audit_archive_bucket = "${local.formatted_env_name}-syslog-audit-archive"

  fluentd_lb_name = "${local.formatted_env_name}-fluentd-lb"

  director_role_id    = data.terraform_remote_state.paperwork.outputs.director_role_id
  om_role_id          = data.terraform_remote_state.paperwork.outputs.om_role_id
  sjb_role_id         = data.terraform_remote_state.paperwork.outputs.sjb_role_id
  concourse_role_id   = data.terraform_remote_state.paperwork.outputs.concourse_role_id
  bosh_role_id        = data.terraform_remote_state.paperwork.outputs.bosh_role_id
  isse_role_id        = data.terraform_remote_state.paperwork.outputs.isse_role_id
  super_user_ids      = data.terraform_remote_state.paperwork.outputs.super_user_ids
  super_user_role_ids = data.terraform_remote_state.paperwork.outputs.super_user_role_ids

  bootstrap_role_id  = data.terraform_remote_state.paperwork.outputs.bootstrap_role_id
  foundation_role_id = data.terraform_remote_state.paperwork.outputs.foundation_role_id
}

data "aws_subnet" "private_subnets" {
  count = length(local.private_subnets)
  id    = local.private_subnets[count.index]
}

data "aws_iam_role" "fluentd" {
  name = data.terraform_remote_state.paperwork.outputs.fluentd_role_name
}

resource "aws_s3_bucket" "syslog_archive" {
  bucket        = local.syslog_archive_bucket
  acl           = "private"
  tags          = local.modified_tags
  force_destroy = var.force_destroy_buckets

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = local.s3_logs_bucket
    target_prefix = "${local.syslog_archive_bucket}/"
  }
}

module "syslog_archive_bucket_policy" {
  source              = "../../modules/bucket/policy/generic"
  bucket_arn          = aws_s3_bucket.syslog_archive.arn
  read_write_role_ids = [data.aws_iam_role.fluentd.unique_id]
  read_only_role_ids = concat(local.super_user_role_ids, [
    local.director_role_id,
    local.om_role_id,
    local.bosh_role_id,
    local.sjb_role_id,
    local.concourse_role_id,
    local.bootstrap_role_id,
    local.foundation_role_id
  ], [local.isse_role_id])
  read_only_user_ids = local.super_user_ids
  disable_delete     = true
}

resource "aws_s3_bucket_policy" "syslog_archive_bucket_policy_attachment" {
  bucket = aws_s3_bucket.syslog_archive.bucket
  policy = module.syslog_archive_bucket_policy.json
}

resource "aws_s3_bucket" "syslog_audit_archive" {
  bucket        = local.syslog_audit_archive_bucket
  acl           = "private"
  tags          = local.modified_tags
  force_destroy = var.force_destroy_buckets

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = local.s3_logs_bucket
    target_prefix = "${local.syslog_audit_archive_bucket}/"
  }
}

module "syslog_audit_archive_bucket_policy" {
  source              = "../../modules/bucket/policy/generic"
  bucket_arn          = aws_s3_bucket.syslog_audit_archive.arn
  read_write_role_ids = [data.aws_iam_role.fluentd.unique_id]
  read_only_role_ids = concat(local.super_user_role_ids, [
    local.director_role_id,
    local.om_role_id,
    local.bosh_role_id,
    local.sjb_role_id,
    local.concourse_role_id,
    local.bootstrap_role_id,
    local.foundation_role_id
  ], [local.isse_role_id])
  read_only_user_ids = local.super_user_ids
  disable_delete     = true
}

resource "aws_s3_bucket_policy" "syslog_audit_archive_bucket_policy_attachment" {
  bucket = aws_s3_bucket.syslog_audit_archive.bucket
  policy = module.syslog_audit_archive_bucket_policy.json
}

resource "aws_cloudwatch_log_group" "fluentd_audit_syslog_group" {
  name       = local.audit_log_group_name
  kms_key_id = data.terraform_remote_state.paperwork.outputs.kms_key_arn
  tags       = local.modified_tags
}

resource "aws_cloudwatch_log_group" "fluentd_syslog_group" {
  name       = local.log_group_name
  kms_key_id = data.terraform_remote_state.paperwork.outputs.kms_key_arn
  tags       = local.modified_tags
}

resource "aws_ebs_volume" "fluentd_data" {
  count             = length(local.private_subnets)
  availability_zone = element(data.aws_subnet.private_subnets.*.availability_zone, count.index)
  size              = 100
  encrypted         = true
  kms_key_id        = data.terraform_remote_state.paperwork.outputs.kms_key_arn
}

module "bootstrap" {
  source        = "../../modules/eni_per_subnet"
  ingress_rules = local.fluentd_ingress_rules
  egress_rules  = local.fluentd_egress_rules
  subnet_ids    = local.subnets
  create_eip    = "false"
  eni_count     = "3"
  tags          = local.modified_tags
}

resource "aws_lb" "fluentd_lb" {
  name                             = local.fluentd_lb_name
  internal                         = true
  load_balancer_type               = "network"
  subnets                          = data.terraform_remote_state.enterprise-services.outputs.public_subnet_ids
  enable_cross_zone_load_balancing = true
  tags = merge(
    local.modified_tags,
    {
      "Name" = local.fluentd_lb_name
    },
  )
}

resource "aws_lb_target_group" "fluentd_nlb_syslog" {
  name_prefix = "syslog"
  port        = module.syslog_ports.syslog_port
  protocol    = "TCP"
  vpc_id      = data.terraform_remote_state.paperwork.outputs.es_vpc_id

  tags = {
    Name = "${local.formatted_env_name}-fluentd${module.syslog_ports.syslog_port}"
  }

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    port     = 8888
    protocol = "TCP"
  }

  stickiness {
    enabled = false
    type    = "lb_cookie"
  }
}

resource "aws_lb_target_group" "fluentd_nlb_apps_syslog" {
  name_prefix = "applog"
  port        = module.syslog_ports.apps_syslog_port
  protocol    = "TCP"
  vpc_id      = data.terraform_remote_state.paperwork.outputs.es_vpc_id

  tags = {
    Name = "${local.formatted_env_name}-fluentd${module.syslog_ports.syslog_port}"
  }

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    port     = 8888
    protocol = "TCP"
  }

  stickiness {
    enabled = false
    type    = "lb_cookie"
  }
}


resource "aws_lb_listener" "fluentd_nlb_syslog" {
  load_balancer_arn = aws_lb.fluentd_lb.arn
  protocol          = "TCP"
  port              = module.syslog_ports.syslog_port

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fluentd_nlb_syslog.arn
  }
}

resource "aws_lb_listener" "fluentd_nlb_apps_syslog" {
  load_balancer_arn = aws_lb.fluentd_lb.arn
  protocol          = "TCP"
  port              = module.syslog_ports.apps_syslog_port

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fluentd_nlb_apps_syslog.arn
  }
}


variable "remote_state_region" {
}

variable "remote_state_bucket" {
}

variable "force_destroy_buckets" {
  type    = bool
  default = false
}

variable "global_vars" {
  type = any
}

output "fluentd_eni_ids" {
  value = module.bootstrap.eni_ids
}

output "fluentd_eni_ips" {
  value = module.bootstrap.eni_ips
}

output "volume_id" {
  value = aws_ebs_volume.fluentd_data.*.id
}

output "audit_log_group_name" {
  value = aws_cloudwatch_log_group.fluentd_audit_syslog_group.name
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.fluentd_syslog_group.name
}

output "s3_bucket_syslog_archive" {
  value = aws_s3_bucket.syslog_archive.id
}

output "s3_bucket_syslog_audit_archive" {
  value = aws_s3_bucket.syslog_audit_archive.id
}

output "fluentd_lb_syslog_tg_arn" {
  value = aws_lb_target_group.fluentd_nlb_syslog.arn
}

output "fluentd_lb_apps_syslog_tg_arn" {
  value = aws_lb_target_group.fluentd_nlb_apps_syslog.arn
}

output "fluentd_lb_dns_name" {
  value = aws_lb.fluentd_lb.dns_name
}
