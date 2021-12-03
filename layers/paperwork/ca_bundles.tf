
variable "bosh_vms_system_ca_certs" {
  type = set(string)
}

data "aws_s3_bucket_object" "bosh_vms_ca_certs" {
  for_each = var.bosh_vms_system_ca_certs
  bucket = var.cert_bucket
  key    = each.key
}

locals {
  bosh_system_ca_bundle = join("\n",[for cert in data.aws_s3_bucket_object.bosh_vms_ca_certs : cert.body])
}

output "bosh_system_ca_bundle"{
  value = local.bosh_system_ca_bundle
}

variable "router_trusted_ca_certs" {
  type = set(string)
}

data "aws_s3_bucket_object" "router_trusted_ca_certs_bundle" {
  for_each = var.router_trusted_ca_certs
  bucket = var.cert_bucket
  key    = each.key
}

locals {
  router_trusted_ca_certs_bundle = join("\n",[for cert in data.aws_s3_bucket_object.router_trusted_ca_certs_bundle : cert.body])
}

output "router_trusted_ca_certs_bundle"{
  value = local.router_trusted_ca_certs_bundle
}

variable "system_ca_certs" {
  type = set(string)
}

data "aws_s3_bucket_object" "system_ca_certs" {
  for_each = var.system_ca_certs
  bucket = var.cert_bucket
  key    = each.key
}

locals {
  system_ca_certs_bundle = join("\n",[for cert in data.aws_s3_bucket_object.system_ca_certs : cert.body])
}

output "system_ca_certs_bundle"{
  value = local.system_ca_certs_bundle
}




data "aws_s3_bucket_object" "loki_ca_certs" {
  for_each = var.loki_config.loki_client_cert_signer_ca_certs
  bucket = var.cert_bucket
  key    = each.key
}

locals {
  loki_ca_certs_bundle = join("\n",[for cert in data.aws_s3_bucket_object.loki_ca_certs : cert.body])
}

output "loki_ca_certs_bundle"{
  value = var.enable_loki ? local.loki_ca_certs_bundle : ""
}





variable "syslog_ca_certs" {
  type = set(string)
}

data "aws_s3_bucket_object" "syslog_ca_certs" {
  for_each = var.syslog_ca_certs
  bucket = var.cert_bucket
  key    = each.key
}

locals {
  syslog_ca_certs_bundle = join("\n",[for cert in data.aws_s3_bucket_object.syslog_ca_certs : cert.body])
}

output "syslog_ca_certs_bundle"{
  value = local.syslog_ca_certs_bundle
}

variable "concourse_ca_certs" {
  type = set(string)
}

data "aws_s3_bucket_object" "concourse_ca_certs" {
  for_each = var.concourse_ca_certs
  bucket = var.cert_bucket
  key    = each.key
}

locals {
  concourse_ca_certs_bundle = join("\n",[for cert in data.aws_s3_bucket_object.concourse_ca_certs : cert.body])
}

output "concourse_ca_certs_bundle"{
  value = local.concourse_ca_certs_bundle
}

variable "grafana_ca_certs" {
  type = set(string)
}

data "aws_s3_bucket_object" "grafana_ca_certs" {
  for_each = var.grafana_ca_certs
  bucket = var.cert_bucket
  key    = each.key
}

locals {
  grafana_ca_certs_bundle = join("\n",[for cert in data.aws_s3_bucket_object.grafana_ca_certs : cert.body])
}

output "grafana_ca_certs_bundle"{
  value = local.grafana_ca_certs_bundle
}
