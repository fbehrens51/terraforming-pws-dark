variable "region" {}
variable "public_bucket_name" {
}

variable "public_bucket_url" {
}

variable "storage_bucket" {
}

variable "root_domain" {
}

variable "loki_bundle_key" {
  description = "Loki bundle S3 object key, aka filename."
}

variable "loki_ips" {
  type = list(string)
}

variable "ca_cert" {}
variable "server_cert" {}
variable "server_key" {}

variable "client_cert_signer" {}
variable "retention_period" {}
