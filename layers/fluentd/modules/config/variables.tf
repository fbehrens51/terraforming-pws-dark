variable "public_bucket_name" {}
variable "public_bucket_url" {}
variable "ca_cert" {}
variable "fluentd_bundle_key" {
  description = "Fluentd bundle S3 object key, aka filename."
}
variable "server_key" {}
variable "server_cert" {}
variable "s3_logs_bucket" {}
variable "cloudwatch_audit_log_group_name" {}
variable "cloudwatch_log_group_name" {}
variable "cloudwatch_log_stream_name" {}
variable "s3_audit_logs_bucket" {}
variable "region" {}
variable "s3_path" {}

variable "loki_config" {
  type = object({
    enabled          = bool
    loki_url         = string
    loki_password    = string
    loki_username    = string
    loki_client_cert = string
    loki_client_key  = string
  })
}

