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

variable "clamav_cpu_limit" {
  description = "The enforced CPU limit.  This value is in percentage, 0 up to 100."
}

variable "clamav_enable_on_access_scanning" {
  description = "When set to true, the clamav add-on will scan files on access."
}

variable "clamav_no_upstream_mirror" {
  description = "When set to true, the operator is required to initialize and update the virus definitions manually using SSH."
}

variable "clamav_external_mirrors" {
  description = "This option is only relevant when `clamav_no_upstream_mirror` is set to false.  A list of external mirrors to use.  If empty, the official mirror will be used."
  type        = "list"
}

variable "clamav_mirror_instance_type" {
  default = "automatic"
}

variable "clamav_release_public_bucket_key" {
  description = "The object key of the clamav release. This will be used to add clamav to the bosh director."
}

variable "clamav_release_sha1" {
  description = "The object sha1 of the clamav release. This will be used to add clamav to the bosh director."
}

variable "ipsec_log_level" {}
variable "ipsec_optional" {}

variable "runtime_config_product_version" {}

variable "extra_user_name" {
  description = "The username of the extra user that will be added to all bosh managed VMs"
  default     = ""
}

variable "extra_user_public_key" {
  description = "The SSH public key of the extra user that will be added to all bosh managed VMs"
  default     = ""
}

variable "extra_user_sudo" {
  description = "Whether to grant sudo acces to the extra user"
  default     = false
}

variable "concourse_version" {}

variable "concourse_users" {
  description = "An array of usernames that will be given admin permissions in concourse.  The passwords of those users will be automatically generated."
  type        = "list"
}
