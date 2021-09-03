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

module "syslog_ports" {
  source = "../../modules/syslog_ports"
}

locals {
  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} loki"
  modified_tags = merge(
    var.global_vars["global_tags"],
    {
      "Name" = local.modified_name
    },
  )

  subnets = data.terraform_remote_state.enterprise-services.outputs.private_subnet_ids

  public_subnet = data.terraform_remote_state.enterprise-services.outputs.public_subnet_ids[0]

  loki_ingress_rules = [
    {
      description = "Allow ssh/22 from everywhere"
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      description = "Allow http/${module.syslog_ports.loki_http_port} from everywhere"
      port        = module.syslog_ports.loki_http_port
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      description = "Allow grpc/${module.syslog_ports.loki_grpc_port} from everywhere"
      port        = module.syslog_ports.loki_grpc_port
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
  ]

  loki_egress_rules = [
    {
      description = "Allow all protocols/ports to everywhere"
      port        = "0"
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  private_subnets = data.terraform_remote_state.enterprise-services.outputs.private_subnet_ids

  formatted_env_name = replace(local.env_name, " ", "-")

  syslog_audit_archive_bucket = "${local.formatted_env_name}-syslog-audit-archive"

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

data "aws_iam_role" "loki" {
  name = data.terraform_remote_state.paperwork.outputs.loki_role_name
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
  read_write_role_ids = [data.aws_iam_role.loki.unique_id]
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

resource "aws_lb" "loki_lb" {
  name                             = local.loki_lb_name
  internal                         = true
  load_balancer_type               = "network"
  subnets                          = data.terraform_remote_state.enterprise-services.outputs.public_subnet_ids
  enable_cross_zone_load_balancing = true
  tags = merge(
    local.modified_tags,
    {
      "Name" = local.loki_lb_name
    },
  )
}

resource "aws_lb_target_group" "loki_nlb_syslog" {
  name_prefix = "syslog"
  port        = module.syslog_ports.loki_http_port
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.paperwork.outputs.es_vpc_id

  tags = {
    Name = "${local.formatted_env_name}-loki${module.syslog_ports.loki_http_port}"
  }

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    port = module.syslog_ports.loki_http_port
    path = "/ready"
  }
}

resource "aws_lb_listener" "loki_nlb_syslog" {
  load_balancer_arn = aws_lb.loki_lb.arn
  protocol          = "HTTP"
  port              = module.syslog_ports.loki_http_port

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.loki_nlb_syslog.arn
  }
}

module "bootstrap" {
  source        = "../../modules/eni_per_subnet"
  ingress_rules = local.loki_ingress_rules
  egress_rules  = local.loki_egress_rules
  subnet_ids    = local.subnets
  create_eip    = "false"
  eni_count     = "3"
  tags          = local.modified_tags
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

output "loki_eni_ids" {
  value = module.bootstrap.eni_ids
}

output "loki_eni_ips" {
  value = module.bootstrap.eni_ips
}


