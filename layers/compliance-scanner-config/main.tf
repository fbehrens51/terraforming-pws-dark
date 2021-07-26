variable "global_vars" {
  type = any
}

variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

//from global vars
variable "availability_zones" {
  type = list(string)
}

variable "singleton_availability_zone" {
}

variable "ntp_servers" {
  type = list(string)
}

variable "compliance_scanner_config" {
  default = "pas/compliance_scanner_tile_config.yml"
}

variable "region" {
}

variable "force_destroy_buckets" {
  type    = bool
  default = false
}

terraform {
  backend "s3" {
  }
}

data "aws_region" "current" {
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

module "domains" {
  source = "../../modules/domains"

  root_domain = local.root_domain
}

module "syslog_ports" {
  source = "../../modules/syslog_ports"
}

locals {
  env_name              = var.global_vars.env_name
  bucket_name           = "${replace(local.env_name, " ", "-")}-compliance-scans-pas"
  root_domain           = data.terraform_remote_state.paperwork.outputs.root_domain
  s3_logs_bucket        = data.terraform_remote_state.paperwork.outputs.s3_logs_bucket
  director_role_id      = data.terraform_remote_state.paperwork.outputs.director_role_id
  om_role_id            = data.terraform_remote_state.paperwork.outputs.om_role_id
  bosh_role_id          = data.terraform_remote_state.paperwork.outputs.bosh_role_id
  sjb_role_id           = data.terraform_remote_state.paperwork.outputs.sjb_role_id
  concourse_role_id     = data.terraform_remote_state.paperwork.outputs.concourse_role_id
  isse_role_id          = data.terraform_remote_state.paperwork.outputs.isse_role_id
  super_user_ids        = data.terraform_remote_state.paperwork.outputs.super_user_ids
  super_user_role_ids   = data.terraform_remote_state.paperwork.outputs.super_user_role_ids
  oscap_store_role_name = data.terraform_remote_state.paperwork.outputs.bucket_role_name
}

module "compliance_scanner_config" {
  source                      = "../../modules/compliance-scanner/config"
  scale                       = data.terraform_remote_state.scaling-params.outputs.instance_types
  secrets_bucket_name         = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
  compliance_scanner_config   = var.compliance_scanner_config
  network_name                = data.terraform_remote_state.paperwork.outputs.pas_network_name
  availability_zones          = var.availability_zones
  singleton_availability_zone = var.singleton_availability_zone
  ntp_servers                 = var.ntp_servers
  syslog_host                 = module.domains.fluentd_fqdn
  syslog_port                 = module.syslog_ports.syslog_port
  syslog_ca_cert              = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs
  custom_ssh_banner           = data.terraform_remote_state.paperwork.outputs.custom_ssh_banner
  reports_bucket_name         = local.bucket_name
  reports_bucket_region       = data.aws_region.current.name
}

resource "aws_s3_bucket" "compliance_scanner_bucket" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy_buckets

  versioning {
    enabled = false
  }
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
    target_prefix = "${local.bucket_name}/"
  }

  tags = merge(
    var.global_vars["global_tags"],
    {
      "Name" = "Compliance Scanner Results Bucket"
    },
  )
}

data "aws_iam_role" "bucket_role" {
  name = local.oscap_store_role_name
}

module "compliance_scanner_bucket_policy" {
  source              = "../../modules/bucket/policy/generic"
  bucket_arn          = aws_s3_bucket.compliance_scanner_bucket.arn
  read_write_role_ids = [data.aws_iam_role.bucket_role.unique_id]
  read_only_role_ids = concat(local.super_user_role_ids, [
    local.director_role_id,
    local.om_role_id,
    local.bosh_role_id,
    local.sjb_role_id,
    local.concourse_role_id
  ], [local.isse_role_id])
  read_only_user_ids = local.super_user_ids
}

resource "aws_s3_bucket_policy" "compliance_scanner_bucket_policy_attachment" {
  bucket = aws_s3_bucket.compliance_scanner_bucket.bucket
  policy = module.compliance_scanner_bucket_policy.json
}
