terraform {
  backend "s3" {
  }
}

module "providers" {
  source = "../../modules/dark_providers"
}

provider "aws" {
}

data "aws_region" "current" {
}

locals {
  trusted_with_additional_ca_certs = "${data.aws_s3_bucket_object.trusted_ca_certs.body}${data.aws_s3_bucket_object.additional_trusted_ca_certs.body}"
  bucket_prefix                    = replace(local.env_name_prefix, " ", "-")
  reporting_bucket_name            = "${local.bucket_prefix}-reporting-bucket"
  public_bucket_name               = "${local.bucket_prefix}-public-bucket"

  s3_service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  bot_user_data   = <<DOC
#cloud-config
merge_how:
  - name: list
    settings: [append]
  - name: dict
    settings: [no_replace, recurse_list]

users:
  - name: bot
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: bosh_sshers
    shell: /bin/bash
    lock_passwd: true
    ssh_authorized_keys:
      - ${module.bot_host_key_pair.public_key_openssh}
DOC

  scanner_username  = "security_scanner"
  scanner_user_data = <<DOC
#cloud-config
merge_how:
  - name: list
    settings: [append]
  - name: dict
    settings: [no_replace, recurse_list]

users:
  - name: ${local.scanner_username}
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: bosh_sshers
    shell: /bin/bash
    lock_passwd: true
    ssh_authorized_keys:
      - ${tls_private_key.scanner_private_key.public_key_openssh}
DOC
}

resource "aws_vpc_endpoint" "iso_s3" {
  vpc_id       = var.iso_vpc_ids[count.index]
  count        = length(var.iso_vpc_ids)
  service_name = local.s3_service_name
}

resource "aws_vpc_endpoint" "pas_s3" {
  vpc_id       = var.pas_vpc_id
  service_name = local.s3_service_name
}

resource "aws_vpc_endpoint" "cp_s3" {
  vpc_id       = var.cp_vpc_id
  service_name = local.s3_service_name
}

resource "aws_vpc_endpoint" "es_s3" {
  vpc_id       = var.es_vpc_id
  service_name = local.s3_service_name
}

resource "aws_vpc_endpoint" "bastion_s3" {
  vpc_id       = var.bastion_vpc_id
  service_name = local.s3_service_name
}

# There are several scenarios relevant to accessing this bucket:
#   1. Unauthenticated access from within the VPC
#      - The bucket policy applies and there is an explicit allow for requests via the vpc endpoint.
#   2. Authenticated access outside the VPC
#      - The identity policy applies and there is an explicit allow (likely for s3:*)
#   3. Unauthenticated access outside the VPC
#      - The bucket policy applies and the request is denied because there is no explicit allow
# This comes from AWS docs here: https://aws.amazon.com/premiumsupport/knowledge-center/s3-private-connection-no-authentication/
data "aws_iam_policy_document" "public_bucket_policy" {
  // Allow unauthenticated access only via the vpc endpoints
  statement {
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:ListBucket"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:sourceVpce"

      values = concat([
        aws_vpc_endpoint.pas_s3.id,
        aws_vpc_endpoint.es_s3.id,
        aws_vpc_endpoint.cp_s3.id,
        aws_vpc_endpoint.bastion_s3.id,
        ],
      aws_vpc_endpoint.iso_s3.*.id)
    }

    resources = [aws_s3_bucket.public_bucket.arn, "${aws_s3_bucket.public_bucket.arn}/*"]
  }

  statement {
    effect  = "Deny"
    actions = ["s3:*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"

      values = ["false"]
    }

    resources = [aws_s3_bucket.public_bucket.arn, "${aws_s3_bucket.public_bucket.arn}/*"]
  }
}

resource "aws_s3_bucket" "s3_logs_bucket" {
  bucket        = "${local.bucket_prefix}-s3-logs"
  acl           = "log-delivery-write"
  force_destroy = var.force_destroy_buckets

  //use account's default S3 encryption key
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  tags = {
    "Name" = "${local.env_name_prefix} S3 Logs Bucket"
  }
}

data "aws_iam_policy_document" "s3_logs_bucket_policy" {
  //Read Only statement
  statement {
    effect  = "Allow"
    actions = ["s3:Get*", "s3:List*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringLike"
      variable = "aws:userid"
      values   = ["${data.aws_iam_role.isse_role.unique_id}:*", "${data.aws_iam_role.director_role.unique_id}:*"]

    }
    resources = [aws_s3_bucket.s3_logs_bucket.arn, "${aws_s3_bucket.s3_logs_bucket.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "s3_logs_bucket_policy_attachment" {
  bucket = aws_s3_bucket.s3_logs_bucket.bucket
  policy = data.aws_iam_policy_document.s3_logs_bucket_policy.json
}

resource "aws_s3_bucket" "reporting_bucket" {
  bucket_prefix = local.reporting_bucket_name
  force_destroy = var.force_destroy_buckets
  //  using account's default S3 encryption key
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
  logging {
    target_bucket = aws_s3_bucket.s3_logs_bucket.bucket
    target_prefix = "${local.reporting_bucket_name}/"
  }
}

resource "null_resource" "secrets_logging" {
  provisioner "local-exec" {
    on_failure  = fail
    interpreter = ["bash", "-c"]
    environment = {
      bucket = var.cert_bucket
      bp = jsonencode({
        "LoggingEnabled" = {
          "TargetPrefix" = "${var.cert_bucket}/",
          "TargetBucket" = aws_s3_bucket.s3_logs_bucket.bucket
        }
      })
    }
    command = <<-EOF
      aws s3api put-bucket-logging --bucket $${bucket} --bucket-logging-status="$${bp}"
    EOF
  }
}

data "aws_iam_role" "isse_role" {
  name = var.isse_role_name
}

data "aws_iam_role" "ent_tech_read_role" {
  name = var.ent_tech_read_role_name
}

data "aws_iam_role" "director_role" {
  name = var.director_role_name
}

data "aws_iam_role" "om_role" {
  name = var.om_role_name
}

data "aws_iam_role" "sjb_role" {
  name = var.sjb_role_name
}

data "aws_iam_role" "concourse_role" {
  name = var.concourse_role_name
}

data "aws_iam_role" "bosh_role" {
  name = var.bosh_role_name
}

data "aws_iam_user" "super_users" {
  count     = length(var.account_super_user_names)
  user_name = element(var.account_super_user_names, count.index)
}


data "aws_iam_role" "super_user_roles" {
  count = length(var.account_super_user_role_names)
  name  = element(var.account_super_user_role_names, count.index)
}

module "reporting_bucket_policy" {
  source              = "../../modules/bucket/policy/generic"
  bucket_arn          = aws_s3_bucket.reporting_bucket.arn
  read_write_role_ids = [data.aws_iam_role.director_role.unique_id]
  read_only_role_ids = concat([
    data.aws_iam_role.director_role.unique_id,
    data.aws_iam_role.om_role.unique_id,
    data.aws_iam_role.bosh_role.unique_id,
    data.aws_iam_role.sjb_role.unique_id,
    data.aws_iam_role.concourse_role.unique_id
  ], data.aws_iam_role.super_user_roles.*.unique_id, [data.aws_iam_role.isse_role.unique_id])
  read_only_user_ids = data.aws_iam_user.super_users.*.user_id
}

resource "aws_s3_bucket_policy" "reporting_bucket_policy_attachment" {
  bucket = aws_s3_bucket.reporting_bucket.bucket
  policy = module.reporting_bucket_policy.json
}


resource "aws_s3_bucket" "public_bucket" {
  bucket_prefix = local.public_bucket_name
  force_destroy = var.force_destroy_buckets


  //use sse-s3 instead of KMS for public bucket to allow https call to continue to work
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  logging {
    target_bucket = aws_s3_bucket.s3_logs_bucket.bucket
    target_prefix = "${local.public_bucket_name}/"
  }
}

resource "aws_s3_bucket_policy" "public_bucket_policy_attachement" {
  bucket = aws_s3_bucket.public_bucket.bucket
  policy = data.aws_iam_policy_document.public_bucket_policy.json
}


resource "tls_private_key" "scanner_private_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}


resource "aws_s3_bucket_object" "scanner_public_key" {
  bucket  = var.cert_bucket
  key     = "scanner_public_key"
  content = tls_private_key.scanner_private_key.public_key_openssh
}

module "bot_host_key_pair" {
  source   = "../../modules/key_pair"
  key_name = "${local.env_name_prefix}-bot"
}

module "node_exporter_client_config" {
  source                 = "../../modules/node_exporter"
  node_exporter_location = var.node_exporter_object_url
  public_bucket_name     = aws_s3_bucket.public_bucket.bucket
  public_bucket_url      = local.public_bucket_url
  server_cert_pem        = data.aws_s3_bucket_object.grafana_server_cert.body
  server_key_pem         = data.aws_s3_bucket_object.grafana_server_key.body
}

module "amazon2_clam_av_client_config" {
  source                     = "../../modules/clamav/amzn2_systemd_client"
  clamav_db_mirror           = var.clamav_db_mirror
  custom_repo_url            = var.custom_clamav_yum_repo_url
  public_bucket_name         = aws_s3_bucket.public_bucket.bucket
  public_bucket_url          = local.public_bucket_url
  clamav_rpms_pkg_object_url = var.clamav_rpms_pkg_object_url

}

module "amazon2_system_certs_user_data" {
  source             = "../../modules/cloud_init/certs"
  ca_chain           = local.trusted_with_additional_ca_certs
  public_bucket_name = aws_s3_bucket.public_bucket.bucket
  public_bucket_url  = local.public_bucket_url
}

module "postfix_client_config" {
  source             = "../../modules/postfix_client"
  public_bucket_name = aws_s3_bucket.public_bucket.bucket
  public_bucket_url  = local.public_bucket_url
  root_domain        = var.root_domain
  smtp_from          = var.smtp_from
}

module "server_hardening_config" {
  source             = "../../modules/cloud_init/server_hardening"
  public_bucket_name = aws_s3_bucket.public_bucket.bucket
  public_bucket_url  = local.public_bucket_url
}

module "custom_banner_config" {
  source             = "../../modules/cloud_init/custom_banner"
  ssh_banner         = file(var.custom_ssh_banner_file)
  public_bucket_name = aws_s3_bucket.public_bucket.bucket
  public_bucket_url  = local.public_bucket_url
}

module "om_user_accounts_config" {
  source                  = "../../modules/cloud_init/user_accounts"
  user_accounts_user_data = [file("om_user_data.yml"), local.bot_user_data, local.scanner_user_data]
  public_bucket_name      = aws_s3_bucket.public_bucket.bucket
  public_bucket_url       = local.public_bucket_url
}

module "bot_user_accounts_config" {
  source                  = "../../modules/cloud_init/user_accounts"
  user_accounts_user_data = [file("user_data.yml"), local.bot_user_data, local.scanner_user_data]
  public_bucket_name      = aws_s3_bucket.public_bucket.bucket
  public_bucket_url       = local.public_bucket_url
}

module "tag_completion_config" {
  source             = "../../modules/cloud_init/completion_tag"
  public_bucket_name = aws_s3_bucket.public_bucket.bucket
  public_bucket_url  = local.public_bucket_url
}

module "tag_completion_config_om" {
  source             = "../../modules/cloud_init/completion_tag_om"
  public_bucket_name = aws_s3_bucket.public_bucket.bucket
  public_bucket_url  = local.public_bucket_url
}

variable "force_destroy_buckets" {
  type    = bool
  default = false
}

variable "node_exporter_object_url" {
  default     = ""
  description = "Location of the node_exporter release. If not specified, the node_exporter agent will not be installed."
}

variable "clamav_db_mirror" {
}

variable "custom_clamav_yum_repo_url" {
  default = ""
}

variable "global_vars" {
  type = any
}

variable "root_domain" {
}

variable "smtp_from" {
}

variable "smtp_to" {
}

variable "cert_bucket" {
}

variable "iso_vpc_ids" {
  type = list(string)
}

variable "pas_vpc_id" {
}

variable "pas_vpc_dns" {
}

variable "control_plane_vpc_dns" {
  type = list(string)
}

variable "bastion_vpc_id" {
}

variable "es_vpc_id" {
}

variable "cp_vpc_id" {
}

variable "fluentd_role_name" {
}

variable "isse_role_name" {
}

variable "ent_tech_read_role_name" {
}

variable "instance_tagger_role_name" {
}

variable "director_role_name" {
}

variable "om_role_name" {
}

variable "bosh_role_name" {
}

variable "sjb_role_name" {
}

variable "concourse_role_name" {
}

variable "transfer_key_arn" {}

variable "kms_key_id" {
}

variable "kms_key_arn" {
}

variable "tsdb_role_name" {
}

variable "bucket_role_name" {
}

variable "platform_automation_engine_worker_role_name" {
}

variable "clamav_rpms_pkg_object_url" {
}

variable "ldap_basedn" {
}

variable "ldap_dn" {
}

variable "ldap_host" {
}

variable "ldap_port" {
}

variable "ldap_role_attr" {
}

variable "system_domain" {
}

variable "apps_domain" {
}

variable "ldap_password_s3_path" {
}

variable "s3_endpoint" {
}

variable "check_cloud_init" {
  default = true
}

data "aws_s3_bucket_object" "ldap_password" {
  bucket = var.cert_bucket
  key    = var.ldap_password_s3_path
}

variable "root_ca_cert_s3_path" {
}

data "aws_s3_bucket_object" "root_ca_cert" {
  bucket = var.cert_bucket
  key    = var.root_ca_cert_s3_path
}

variable "router_trusted_ca_certs_s3_path" {
}

data "aws_s3_bucket_object" "router_trusted_ca_certs" {
  bucket = var.cert_bucket
  key    = var.router_trusted_ca_certs_s3_path
}

variable "trusted_ca_certs_s3_path" {
}

data "aws_s3_bucket_object" "trusted_ca_certs" {
  bucket = var.cert_bucket
  key    = var.trusted_ca_certs_s3_path
}

variable "additional_trusted_ca_certs_s3_path" {
}

data "aws_s3_bucket_object" "additional_trusted_ca_certs" {
  bucket = var.cert_bucket
  key    = var.additional_trusted_ca_certs_s3_path
}

variable "rds_ca_cert_s3_path" {
}

data "aws_s3_bucket_object" "rds_ca_cert" {
  bucket = var.cert_bucket
  key    = var.rds_ca_cert_s3_path
}

variable "smtp_relay_password_s3_path" {
}

data "aws_s3_bucket_object" "smtp_relay_password" {
  bucket = var.cert_bucket
  key    = var.smtp_relay_password_s3_path
}

variable "smtp_relay_ca_cert_s3_path" {
}

data "aws_s3_bucket_object" "smtp_relay_ca_cert" {
  bucket = var.cert_bucket
  key    = var.smtp_relay_ca_cert_s3_path
}

variable "grafana_server_cert_s3_path" {
}

data "aws_s3_bucket_object" "grafana_server_cert" {
  bucket = var.cert_bucket
  key    = var.grafana_server_cert_s3_path
}

variable "grafana_server_key_s3_path" {
}

data "aws_s3_bucket_object" "grafana_server_key" {
  bucket = var.cert_bucket
  key    = var.grafana_server_key_s3_path
}

variable "router_server_cert_s3_path" {
}

data "aws_s3_bucket_object" "router_server_cert" {
  bucket = var.cert_bucket
  key    = var.router_server_cert_s3_path
}

variable "router_server_key_s3_path" {
}

data "aws_s3_bucket_object" "router_server_key" {
  bucket = var.cert_bucket
  key    = var.router_server_key_s3_path
}

variable "uaa_server_cert_s3_path" {
}

data "aws_s3_bucket_object" "uaa_server_cert" {
  bucket = var.cert_bucket
  key    = var.uaa_server_cert_s3_path
}

variable "uaa_server_key_s3_path" {
}

data "aws_s3_bucket_object" "uaa_server_key" {
  bucket = var.cert_bucket
  key    = var.uaa_server_key_s3_path
}

variable "vanity_server_cert_s3_path" {
}

data "aws_s3_bucket_object" "vanity_server_cert" {
  bucket = var.cert_bucket
  key    = var.vanity_server_cert_s3_path
}

variable "vanity_server_key_s3_path" {
}

data "aws_s3_bucket_object" "vanity_server_key" {
  bucket = var.cert_bucket
  key    = var.vanity_server_key_s3_path
}

variable "ldap_ca_cert_s3_path" {
}

data "aws_s3_bucket_object" "ldap_ca_cert" {
  bucket = var.cert_bucket
  key    = var.ldap_ca_cert_s3_path
}

variable "ldap_client_cert_s3_path" {
}

data "aws_s3_bucket_object" "ldap_client_cert" {
  bucket = var.cert_bucket
  key    = var.ldap_client_cert_s3_path
}

variable "ldap_client_key_s3_path" {
}

data "aws_s3_bucket_object" "ldap_client_key" {
  bucket = var.cert_bucket
  key    = var.ldap_client_key_s3_path
}

variable "control_plane_star_server_cert_s3_path" {
}

data "aws_s3_bucket_object" "control_plane_star_server_cert" {
  bucket = var.cert_bucket
  key    = var.control_plane_star_server_cert_s3_path
}

variable "control_plane_star_server_key_s3_path" {
}

data "aws_s3_bucket_object" "control_plane_star_server_key" {
  bucket = var.cert_bucket
  key    = var.control_plane_star_server_key_s3_path
}

variable "om_server_cert_s3_path" {
}

data "aws_s3_bucket_object" "om_server_cert" {
  bucket = var.cert_bucket
  key    = var.om_server_cert_s3_path
}

variable "om_server_key_s3_path" {
}

data "aws_s3_bucket_object" "om_server_key" {
  bucket = var.cert_bucket
  key    = var.om_server_key_s3_path
}

variable "fluentd_server_cert_s3_path" {
}

data "aws_s3_bucket_object" "fluentd_server_cert" {
  bucket = var.cert_bucket
  key    = var.fluentd_server_cert_s3_path
}

variable "fluentd_server_key_s3_path" {
}

data "aws_s3_bucket_object" "fluentd_server_key" {
  bucket = var.cert_bucket
  key    = var.fluentd_server_key_s3_path
}

variable "smtp_server_cert_s3_path" {
}

data "aws_s3_bucket_object" "smtp_server_cert" {
  bucket = var.cert_bucket
  key    = var.smtp_server_cert_s3_path
}

variable "smtp_server_key_s3_path" {
}

data "aws_s3_bucket_object" "smtp_server_key" {
  bucket = var.cert_bucket
  key    = var.smtp_server_key_s3_path
}

variable "portal_smoke_test_cert_s3_path" {
}

data "aws_s3_bucket_object" "portal_smoke_test_cert" {
  bucket = var.cert_bucket
  key    = var.portal_smoke_test_cert_s3_path
}

variable "portal_smoke_test_key_s3_path" {
}

variable "custom_ssh_banner_file" {
}

data "aws_s3_bucket_object" "portal_smoke_test_key" {
  bucket = var.cert_bucket
  key    = var.portal_smoke_test_key_s3_path
}

variable "log_forwarder_region" {
  default = ""
}

output "log_forwarder_region" {
  value = var.log_forwarder_region == "" ? data.aws_region.current.name : var.log_forwarder_region
}

variable "cap_url" {
}

variable "cap_root_ca_s3_path" {
}

variable "account_super_user_names" {
  type    = list(string)
  default = []
}

variable "account_super_user_role_names" {
  type    = list(string)
  default = []
}

variable "amzn_ami_id" {
  type = string
}


variable "extra_users" {
  description = "extra users to add to all bosh managed vms"
  default     = []
  type = list(object({
    username       = string
    public_ssh_key = string
    sudo_priv      = bool
  }))
}

variable "endpoint_domain" {
  type = "string"
}

data "aws_ami" "amzn_ami" {
  owners = ["self", "amazon"]
  filter {
    name   = "image-id"
    values = [var.amzn_ami_id]
  }
}

output "amzn_ami_id" {
  value = data.aws_ami.amzn_ami.image_id
}

data "aws_s3_bucket_object" "cap_root_ca" {
  bucket = var.cert_bucket
  key    = var.cap_root_ca_s3_path
}

# This key is used to distinguish between metrics domains in grafana.
resource "random_string" "metrics_key" {
  length  = "10"
  special = false
}

output "metrics_key" {
  value = "${local.env_name_prefix} ${random_string.metrics_key.result}"
}

output "secrets_bucket_name" {
  value = var.cert_bucket
}

output "pas_network_name" {
  value = "pas"
}

output "infrastructure_network_name" {
  value = "infrastructure"
}

output "control_plane_subnet_network_name" {
  value = "control-plane-subnet"
}

output "pas_vpc_dns" {
  value = var.pas_vpc_dns
}

output "control_plane_vpc_dns" {
  value = var.control_plane_vpc_dns
}

output "iso_s3_endpoint_ids" {
  value = {
    for endpoint in aws_vpc_endpoint.iso_s3 :
    endpoint.vpc_id => endpoint.id
  }
}

output "pas_vpc_id" {
  value = var.pas_vpc_id
}

output "bastion_vpc_id" {
  value = var.bastion_vpc_id
}

output "es_vpc_id" {
  value = var.es_vpc_id
}

output "cp_vpc_id" {
  value = var.cp_vpc_id
}

output "sjb_role_name" {
  value = var.sjb_role_name
}

output "fluentd_role_name" {
  value = var.fluentd_role_name
}

output "instance_tagger_role_name" {
  value = var.instance_tagger_role_name
}

output "director_role_name" {
  value = var.director_role_name
}

output "om_role_name" {
  value = var.om_role_name
}

output "bosh_role_name" {
  value = var.bosh_role_name
}

output "concourse_role_name" {
  value = var.concourse_role_name
}

output "kms_key_id" {
  value = var.kms_key_id
}

output "kms_key_arn" {
  value = var.kms_key_arn
}

output "transfer_key_arn" {
  value = var.transfer_key_arn
}

output "tsdb_role_name" {
  value = var.tsdb_role_name
}

output "root_ca_cert" {
  value = data.aws_s3_bucket_object.root_ca_cert.body
}

output "root_ca_cert_path" {
  value = data.aws_s3_bucket_object.root_ca_cert.key
}

output "additional_trusted_ca_certs" {
  value = data.aws_s3_bucket_object.additional_trusted_ca_certs.body
}

output "additional_trusted_ca_certs_path" {
  value = data.aws_s3_bucket_object.additional_trusted_ca_certs.key
}

output "router_trusted_ca_certs" {
  value = data.aws_s3_bucket_object.router_trusted_ca_certs.body
}

output "trusted_ca_certs" {
  value = data.aws_s3_bucket_object.trusted_ca_certs.body
}

output "trusted_with_additional_ca_certs" {
  value = local.trusted_with_additional_ca_certs
}

output "rds_ca_cert" {
  value = data.aws_s3_bucket_object.rds_ca_cert.body
}

output "smtp_relay_ca_cert" {
  value = data.aws_s3_bucket_object.smtp_relay_ca_cert.body
}

output "smtp_relay_password" {
  value = data.aws_s3_bucket_object.smtp_relay_password.body
}

output "grafana_server_cert" {
  value = data.aws_s3_bucket_object.grafana_server_cert.body
}

output "grafana_server_key" {
  value     = data.aws_s3_bucket_object.grafana_server_key.body
  sensitive = true
}

output "router_server_cert" {
  value = data.aws_s3_bucket_object.router_server_cert.body
}

output "router_server_key" {
  value     = data.aws_s3_bucket_object.router_server_key.body
  sensitive = true
}

output "uaa_server_cert" {
  value = data.aws_s3_bucket_object.uaa_server_cert.body
}

output "uaa_server_key" {
  value     = data.aws_s3_bucket_object.uaa_server_key.body
  sensitive = true
}

output "vanity_server_cert" {
  value = data.aws_s3_bucket_object.vanity_server_cert.body
}

output "vanity_server_key" {
  value     = data.aws_s3_bucket_object.vanity_server_key.body
  sensitive = true
}

output "ldap_ca_cert" {
  value = data.aws_s3_bucket_object.ldap_ca_cert.body
}

output "ldap_ca_cert_s3_path" {
  value = var.ldap_ca_cert_s3_path
}

output "ldap_client_cert" {
  value = data.aws_s3_bucket_object.ldap_client_cert.body
}

output "ldap_client_cert_s3_path" {
  value = var.ldap_client_cert_s3_path
}

output "ldap_client_key" {
  value     = data.aws_s3_bucket_object.ldap_client_key.body
  sensitive = true
}

output "ldap_client_key_s3_path" {
  value = var.ldap_client_key_s3_path
}

output "control_plane_star_server_cert" {
  value = data.aws_s3_bucket_object.control_plane_star_server_cert.body
}

output "control_plane_star_server_key" {
  value     = data.aws_s3_bucket_object.control_plane_star_server_key.body
  sensitive = true
}

output "om_server_cert" {
  value = data.aws_s3_bucket_object.om_server_cert.body
}

output "om_server_key" {
  value     = data.aws_s3_bucket_object.om_server_key.body
  sensitive = true
}

output "fluentd_server_cert" {
  value = data.aws_s3_bucket_object.fluentd_server_cert.body
}

output "fluentd_server_key" {
  value     = data.aws_s3_bucket_object.fluentd_server_key.body
  sensitive = true
}

output "smtpd_server_cert" {
  value = data.aws_s3_bucket_object.smtp_server_cert.body
}

output "smtpd_server_key" {
  value     = data.aws_s3_bucket_object.smtp_server_key.body
  sensitive = true
}

output "cap_url" {
  value = var.cap_url
}

output "cap_root_ca_cert" {
  value = data.aws_s3_bucket_object.cap_root_ca.body
}

output "portal_smoke_test_cert" {
  value = data.aws_s3_bucket_object.portal_smoke_test_cert.body
}

output "portal_smoke_test_key" {
  value     = data.aws_s3_bucket_object.portal_smoke_test_key.body
  sensitive = true
}

output "platform_automation_engine_worker_role_name" {
  value = var.platform_automation_engine_worker_role_name
}

output "bucket_role_name" {
  value = var.bucket_role_name
}

output "ldap_basedn" {
  value = var.ldap_basedn
}

output "ldap_dn" {
  value = var.ldap_dn
}

output "ldap_password" {
  value     = data.aws_s3_bucket_object.ldap_password.body
  sensitive = true
}

output "ldap_host" {
  value = var.ldap_host
}

output "ldap_port" {
  value = var.ldap_port
}

output "ldap_role_attr" {
  value = var.ldap_role_attr
}

output "root_domain" {
  value = var.root_domain
}

output "smtp_from" {
  value = var.smtp_from
}

output "smtp_to" {
  value = var.smtp_to
}

output "system_domain" {
  value = var.system_domain
}

output "apps_domain" {
  value = var.apps_domain
}

output "custom_ssh_banner" {
  value = file(var.custom_ssh_banner_file)
}

output "public_bucket_name" {
  value = aws_s3_bucket.public_bucket.bucket
}

locals {
  public_bucket_url = "https://${aws_s3_bucket.public_bucket.bucket}.${var.s3_endpoint}"
  env_name_prefix   = var.global_vars.name_prefix
}

output "public_bucket_url" {
  value = local.public_bucket_url
}

output "pas_s3_vpc_endpoint_id" {
  value = aws_vpc_endpoint.pas_s3.id
}

output "cp_s3_vpc_endpoint_id" {
  value = aws_vpc_endpoint.cp_s3.id
}

output "es_s3_vpc_endpoint_id" {
  value = aws_vpc_endpoint.es_s3.id
}

output "bastion_s3_vpc_endpoint_id" {
  value = aws_vpc_endpoint.bastion_s3.id
}

output "node_exporter_user_data" {
  value = module.node_exporter_client_config.user_data
}

output "amazon2_system_certs_user_data" {
  value = module.amazon2_system_certs_user_data.amazon2_system_certs_user_data
}

output "amazon2_clamav_user_data" {
  value = module.amazon2_clam_av_client_config.amazon2_clamav_user_data
}

output "postfix_client_user_data" {
  value = module.postfix_client_config.postfix_client_user_data
}

output "server_hardening_user_data" {
  value = module.server_hardening_config.server_hardening_user_data
}

output "custom_banner_user_data" {
  value = module.custom_banner_config.custom_banner_user_data
}

output "om_user_accounts_user_data" {
  value = module.om_user_accounts_config.user_accounts_user_data
}

output "bot_user_accounts_user_data" {
  value = module.bot_user_accounts_config.user_accounts_user_data
}

output "completion_tag_user_data" {
  value = module.tag_completion_config.tg_include_user_data
}

output "completion_tag_om_user_data" {
  value = module.tag_completion_config_om.tg_include_user_data
}

output "bot_public_key" {
  value = module.bot_host_key_pair.public_key_openssh
}

output "bot_private_key" {
  value     = module.bot_host_key_pair.private_key_pem
  sensitive = true
}

output "s3_logs_bucket" {
  value = aws_s3_bucket.s3_logs_bucket.bucket
}

output "reporting_bucket" {
  value = aws_s3_bucket.reporting_bucket.bucket
}

output "director_role_id" {
  value = data.aws_iam_role.director_role.unique_id
}

output "om_role_id" {
  value = data.aws_iam_role.om_role.unique_id
}

output "isse_role_id" {
  value = data.aws_iam_role.isse_role.unique_id
}

output "sjb_role_id" {
  value = data.aws_iam_role.sjb_role.unique_id
}

output "concourse_role_id" {
  value = data.aws_iam_role.concourse_role.unique_id
}

output "bosh_role_id" {
  value = data.aws_iam_role.bosh_role.unique_id
}

output "ent_tech_read_role_id" {
  value = data.aws_iam_role.ent_tech_read_role.unique_id
}

output "super_user_ids" {
  value = data.aws_iam_user.super_users.*.user_id
}

output "super_user_role_ids" {
  value = data.aws_iam_role.super_user_roles.*.unique_id
}

output "check_cloud_init" {
  value = var.check_cloud_init
}

output "scanner_private_key" {
  sensitive = true
  value     = tls_private_key.scanner_private_key.private_key_pem
}

output "scanner_public_key" {
  sensitive = true
  value     = tls_private_key.scanner_private_key.public_key_openssh
}

locals {
  extra_bosh_users = [
    {
      username       = local.scanner_username
      public_ssh_key = tls_private_key.scanner_private_key.public_key_openssh
      sudo_priv      = true
    }
  ]
}

output "extra_bosh_users" {
  value = concat(local.extra_bosh_users, var.extra_users)
}

output "env_name" {
  value = var.global_vars.env_name
}

output "region" {
  value = data.aws_region.current.name
}

output "s3_endpoint" {
  value = var.s3_endpoint
}

output "endpoint_domain" {
  value = var.endpoint_domain
}
