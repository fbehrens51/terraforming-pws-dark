variable "region" {}
variable "remote_state_bucket" {}
variable "remote_state_region" {}
variable "singleton_availability_zone" {}
variable "cloud_controller_encrypt_key_secret" {}
variable "credhub_encryption_password" {}
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
variable "apps_manager_global_wrapper_footer_content" {}
variable "apps_manager_global_wrapper_header_content" {}
variable "apps_manager_footer_text" {}
variable "apps_manager_accent_color" {}
variable "apps_manager_global_wrapper_text_color" {}
variable "apps_manager_company_name" {}
variable "apps_manager_global_wrapper_bg_color" {}
variable "apps_manager_favicon_file" {}
variable "apps_manager_square_logo_file" {}
variable "apps_manager_main_logo_file" {}
variable "custom_ssh_banner_file" {}
variable "rds_ca_cert_file" {}
variable "jwt_expiration" {}
variable "redis_ca_cert_file" {}
variable "env_name" {}
variable "internetless" {}
variable "s3_endpoint" {}
variable "ec2_endpoint" {}
variable "elb_endpoint" {}
variable "pivnet_api_token" {}
variable "product_blobs_s3_bucket" {}
variable "product_blobs_s3_endpoint" {}
variable "product_blobs_s3_region" {}
variable "portal_product_version" {}

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
