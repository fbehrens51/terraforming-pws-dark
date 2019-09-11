variable "remote_state_bucket" {}
variable "remote_state_region" {}
variable "singleton_availability_zone" {}
variable "smtp_host" {}
variable "smtp_user" {}
variable "smtp_password" {}
variable "smtp_tls" {}
variable "smtp_from" {}
variable "smtp_port" {}
variable "smtp_recipients" {}
variable "smtp_domain" {}
variable "smtp_enabled" {}
variable "iaas_configuration_endpoints_ca_cert" {}
variable "custom_ssh_banner_file" {}
variable "env_name" {}
variable "internetless" {}
variable "s3_endpoint" {}
variable "ec2_endpoint" {}
variable "elb_endpoint" {}
variable "pivnet_api_token" {}
variable "product_blobs_s3_bucket" {}
variable "product_blobs_s3_endpoint" {}
variable "product_blobs_s3_region" {}

variable "s3_access_key_id" {
  default = ""
}

variable "s3_secret_access_key" {
  default = ""
}

variable "s3_auth_type" {
  default = "iam"
}

variable "ntp_servers" {
  type = "list"
}

variable "tags" {
  type = "map"
}

variable "availability_zones" {
  type = "list"
}

variable "pws_dark_iam_s3_resource_product_version" {}
