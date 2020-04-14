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
  bucket_prefix   = "${replace(var.env_name, " ", "-")}"
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

  tags = {
    "Name" = "${var.env_name} S3 Logs Bucket"
  }
}

resource "aws_s3_bucket" "public_bucket" {
  bucket_prefix = "${local.bucket_prefix}-public-bucket"
  force_destroy = var.force_destroy_buckets

  logging {
    target_bucket = aws_s3_bucket.s3_logs_bucket.bucket
    target_prefix = "log/"
  }
}

resource "aws_s3_bucket_policy" "public_bucket_policy_attachement" {
  bucket = aws_s3_bucket.public_bucket.bucket
  policy = data.aws_iam_policy_document.public_bucket_policy.json
}

module "bot_host_key_pair" {
  source   = "../../modules/key_pair"
  key_name = "${var.env_name}-bot"
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
  source             = "../../modules/clamav/amzn2_systemd_client"
  clamav_db_mirror   = var.clamav_db_mirror
  custom_repo_url    = var.custom_clamav_yum_repo_url
  public_bucket_name = aws_s3_bucket.public_bucket.bucket
  public_bucket_url  = local.public_bucket_url
}

module "custom_banner_config" {
  source             = "../../modules/cloud_init/custom_banner"
  ssh_banner         = file(var.custom_ssh_banner_file)
  public_bucket_name = aws_s3_bucket.public_bucket.bucket
  public_bucket_url  = local.public_bucket_url
}

module "user_accounts_config" {
  source                  = "../../modules/cloud_init/user_accounts"
  user_accounts_user_data = [file("user_data.yml")]
  public_bucket_name      = aws_s3_bucket.public_bucket.bucket
  public_bucket_url       = local.public_bucket_url
}

module "om_user_accounts_config" {
  source                  = "../../modules/cloud_init/user_accounts"
  user_accounts_user_data = [file("om_user_data.yml"), local.bot_user_data]
  public_bucket_name      = aws_s3_bucket.public_bucket.bucket
  public_bucket_url       = local.public_bucket_url
}

module "bot_user_accounts_config" {
  source                  = "../../modules/cloud_init/user_accounts"
  user_accounts_user_data = [file("user_data.yml"), local.bot_user_data]
  public_bucket_name      = aws_s3_bucket.public_bucket.bucket
  public_bucket_url       = local.public_bucket_url
}

variable "force_destroy_buckets" {
  type    = bool
  default = false
}

variable "node_exporter_object_url" {
}

variable "clamav_db_mirror" {
}

variable "custom_clamav_yum_repo_url" {
}

variable "env_name" {
  type = string
}

variable "root_domain" {
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
}

variable "bastion_vpc_id" {
}

variable "es_vpc_id" {
}

variable "cp_vpc_id" {
}

variable "director_role_name" {
}

variable "sjb_role_name" {
}

variable "transfer_key_arn" {}

variable "kms_key_id" {
}

variable "kms_key_arn" {
}

variable "archive_role_name" {
}

variable "splunk_role_name" {
}

variable "tsdb_role_name" {
}

variable "bucket_role_name" {
}

variable "platform_automation_engine_worker_role_name" {
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

variable "concourse_server_cert_s3_path" {
}

data "aws_s3_bucket_object" "concourse_server_cert" {
  bucket = var.cert_bucket
  key    = var.concourse_server_cert_s3_path
}

variable "concourse_server_key_s3_path" {
}

data "aws_s3_bucket_object" "concourse_server_key" {
  bucket = var.cert_bucket
  key    = var.concourse_server_key_s3_path
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

variable "control_plane_om_server_cert_s3_path" {
}

data "aws_s3_bucket_object" "control_plane_om_server_cert" {
  bucket = var.cert_bucket
  key    = var.control_plane_om_server_cert_s3_path
}

variable "control_plane_om_server_key_s3_path" {
}

data "aws_s3_bucket_object" "control_plane_om_server_key" {
  bucket = var.cert_bucket
  key    = var.control_plane_om_server_key_s3_path
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

variable "splunk_logs_server_cert_s3_path" {
}

data "aws_s3_bucket_object" "splunk_logs_server_cert" {
  bucket = var.cert_bucket
  key    = var.splunk_logs_server_cert_s3_path
}

variable "splunk_logs_server_key_s3_path" {
}

data "aws_s3_bucket_object" "splunk_logs_server_key" {
  bucket = var.cert_bucket
  key    = var.splunk_logs_server_key_s3_path
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

variable "splunk_server_cert_s3_path" {
}

data "aws_s3_bucket_object" "splunk_server_cert" {
  bucket = var.cert_bucket
  key    = var.splunk_server_cert_s3_path
}

variable "splunk_server_key_s3_path" {
}

data "aws_s3_bucket_object" "splunk_server_key" {
  bucket = var.cert_bucket
  key    = var.splunk_server_key_s3_path
}

variable "splunk_monitor_server_cert_s3_path" {
}

data "aws_s3_bucket_object" "splunk_monitor_server_cert" {
  bucket = var.cert_bucket
  key    = var.splunk_monitor_server_cert_s3_path
}

variable "splunk_monitor_server_key_s3_path" {
}

data "aws_s3_bucket_object" "splunk_monitor_server_key" {
  bucket = var.cert_bucket
  key    = var.splunk_monitor_server_key_s3_path
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

output "director_role_name" {
  value = var.director_role_name
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

output "archive_role_name" {
  value = var.archive_role_name
}

output "splunk_role_name" {
  value = var.splunk_role_name
}

output "tsdb_role_name" {
  value = var.tsdb_role_name
}

output "root_ca_cert" {
  value = data.aws_s3_bucket_object.root_ca_cert.body
}

output "router_trusted_ca_certs" {
  value = data.aws_s3_bucket_object.router_trusted_ca_certs.body
}

output "trusted_ca_certs" {
  value = data.aws_s3_bucket_object.trusted_ca_certs.body
}

output "trusted_with_additional_ca_certs" {
  value = "${data.aws_s3_bucket_object.trusted_ca_certs.body}${data.aws_s3_bucket_object.additional_trusted_ca_certs.body}"
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

output "concourse_server_cert" {
  value = data.aws_s3_bucket_object.concourse_server_cert.body
}

output "concourse_server_key" {
  value     = data.aws_s3_bucket_object.concourse_server_key.body
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

output "ldap_client_cert" {
  value = data.aws_s3_bucket_object.ldap_client_cert.body
}

output "ldap_client_key" {
  value     = data.aws_s3_bucket_object.ldap_client_key.body
  sensitive = true
}

output "control_plane_om_server_cert" {
  value = data.aws_s3_bucket_object.control_plane_om_server_cert.body
}

output "control_plane_om_server_key" {
  value     = data.aws_s3_bucket_object.control_plane_om_server_key.body
  sensitive = true
}

output "om_server_cert" {
  value = data.aws_s3_bucket_object.om_server_cert.body
}

output "om_server_key" {
  value     = data.aws_s3_bucket_object.om_server_key.body
  sensitive = true
}

output "splunk_logs_server_cert" {
  value = data.aws_s3_bucket_object.splunk_logs_server_cert.body
}

output "splunk_logs_server_key" {
  value     = data.aws_s3_bucket_object.splunk_logs_server_key.body
  sensitive = true
}

output "smtpd_server_cert" {
  value = data.aws_s3_bucket_object.smtp_server_cert.body
}

output "smtpd_server_key" {
  value     = data.aws_s3_bucket_object.smtp_server_key.body
  sensitive = true
}

output "splunk_server_cert" {
  value = data.aws_s3_bucket_object.splunk_server_cert.body
}

output "splunk_server_key" {
  value     = data.aws_s3_bucket_object.splunk_server_key.body
  sensitive = true
}

output "splunk_monitor_server_cert" {
  value = data.aws_s3_bucket_object.splunk_monitor_server_cert.body
}

output "splunk_monitor_server_key" {
  value     = data.aws_s3_bucket_object.splunk_monitor_server_key.body
  sensitive = true
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

output "amazon2_clamav_user_data" {
  value = module.amazon2_clam_av_client_config.amazon2_clamav_user_data
}

output "custom_banner_user_data" {
  value = module.custom_banner_config.custom_banner_user_data
}

output "user_accounts_user_data" {
  value = module.user_accounts_config.user_accounts_user_data
}

output "om_user_accounts_user_data" {
  value = module.om_user_accounts_config.user_accounts_user_data
}

output "bot_user_accounts_user_data" {
  value = module.bot_user_accounts_config.user_accounts_user_data
}

output "bot_private_key" {
  value     = module.bot_host_key_pair.private_key_pem
  sensitive = true
}

output "s3_logs_bucket" {
  value = aws_s3_bucket.s3_logs_bucket.bucket
}
