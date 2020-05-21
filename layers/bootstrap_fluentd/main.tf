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

data "terraform_remote_state" "bastion" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bastion"
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
  env_name      = var.tags["Name"]
  modified_name = "${local.env_name} fluentd"
  modified_tags = merge(
    var.tags,
    {
      "Name" = local.modified_name
    },
  )

  subnets = data.terraform_remote_state.enterprise-services.outputs.private_subnet_ids

  public_subnet = data.terraform_remote_state.enterprise-services.outputs.public_subnet_ids[0]

  fluentd_ingress_rules = [
    {
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port        = module.syslog_ports.syslog_port
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      // node_exporter metrics endpoint for grafana
      port        = "9100"
      protocol    = "tcp"
      cidr_blocks = data.aws_vpc.pas_vpc.cidr_block
    },
    {
      // fluentd metrics endpoint for grafana
      port        = "9200"
      protocol    = "tcp"
      cidr_blocks = data.aws_vpc.pas_vpc.cidr_block
    },
  ]

  fluentd_egress_rules = [
    {
      port        = "0"
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  private_subnets = data.terraform_remote_state.enterprise-services.outputs.private_subnet_ids

  log_group_name = replace("${local.env_name} log group", " ", "_")

  s3_logs_bucket = data.terraform_remote_state.paperwork.outputs.s3_logs_bucket

  syslog_archive_bucket       = "${replace(local.env_name, " ", "-")}-syslog-archive"
  syslog_audit_archive_bucket = "${replace(local.env_name, " ", "-")}-syslog-audit-archive"
}

data "aws_subnet" "private_subnets" {
  count = length(local.private_subnets)
  id    = local.private_subnets[count.index]
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

  logging {
    target_bucket = local.s3_logs_bucket
    target_prefix = "log/"
  }
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

  logging {
    target_bucket = local.s3_logs_bucket
    target_prefix = "log/"
  }
}

resource "aws_cloudwatch_log_group" "fluentd_syslog_group" {
  name       = local.log_group_name
  kms_key_id = data.terraform_remote_state.paperwork.outputs.kms_key_arn
  tags       = local.modified_tags
}

resource "aws_ebs_volume" "fluentd_data" {
  availability_zone = element(data.aws_subnet.private_subnets.*.availability_zone, 0)
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
  eni_count     = "1"
  tags          = local.modified_tags
}

variable "remote_state_region" {
}

variable "remote_state_bucket" {
}

variable "tags" {
  type = map(string)
}

variable "force_destroy_buckets" {
  type    = bool
  default = false
}

output "fluentd_eni_ids" {
  value = module.bootstrap.eni_ids
}

output "fluentd_eni_ips" {
  value = module.bootstrap.eni_ips
}

output "fluentd_eip_ips" {
  value = module.bootstrap.public_ips
}

output "volume_id" {
  value = aws_ebs_volume.fluentd_data.id
}

output "log_group_name" {
  value = local.log_group_name
}

output "s3_bucket_syslog_archive" {
  value = aws_s3_bucket.syslog_archive.id
}

output "s3_bucket_syslog_audit_archive" {
  value = aws_s3_bucket.syslog_audit_archive.id
}

