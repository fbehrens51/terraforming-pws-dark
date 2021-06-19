variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "singleton_availability_zone" {
}

variable "cloud_controller_encrypt_key_secret" {
}

variable "credhub_encryption_password" {
}

variable "director_blobstore_location" {
}

variable "smtp_from" {
}

variable "smtp_recipients" {
}

variable "smtp_domain" {
}

variable "smtp_enabled" {
}

variable "vanity_cert_enabled" {
}

variable "iaas_configuration_endpoints_ca_cert" {
}

variable "apps_manager_global_wrapper_footer_content" {
}

variable "apps_manager_global_wrapper_header_content" {
}

variable "global_vars" {
  type = any
}

variable "s3_endpoint" {
}

variable "ec2_endpoint" {
}

variable "elb_endpoint" {
}

variable "region" {
}

variable "ntp_servers" {
  type = list(string)
}

variable "clamav_external_mirrors" {
  description = "This option is only relevant when `clamav_no_upstream_mirror` is set to false.  A list of external mirrors to use.  If empty, the official mirror will be used."
  type        = list(string)
}

variable "om_create_db_config" {
  description = "om create_db configuration file"
  default     = "pas/om_create_db_config.bash"
}

variable "om_drop_db_config" {
  description = "om drop_db configuration file"
  default     = "pas/om_drop_db_config.bash"
}

variable "om_syslog_config" {
  description = "om syslog configuration file"
  default     = "pas/om_syslog_config.yml"
}

variable "om_tokens_expiration_config" {
  description = "om tokens expiration configuration file"
  default     = "pas/om_tokens_expiration_config.yml"
}

variable "om_ssl_config" {
  description = "om ssl configuration file"
  default     = "pas/om_ssl_config.yml"
}

variable "om_ssh_banner_config" {
  description = "om ssh_banner configuration file"
  default     = "pas/om_ssh_banner_config.yml"
}

variable "cf_config" {
  description = "cf configuration file"
  default     = "pas/cf_config.yml"
}

variable "cf_tools_config" {
  description = "cf_tools tile configuration file"
  default     = "pas/cf_tools_config.yml"
}

variable "director_config" {
  description = "bosh director configuration file"
  default     = "pas/director_config.yml"
}

variable "portal_config" {
  description = "portal configuration file"
  default     = "pas/portal_config.yml"
}

variable "runtime_config" {
  description = "runtime configuration file"
  default     = "pas/runtime_config_tile_config.yml"
}

variable "clamav_addon_config" {
  description = "clamav addon configuration file"
  default     = "pas/clamav_addon_tile_config.yml"
}

variable "clamav_mirror_config" {
  description = "clamav mirror configuration file"
  default     = "pas/clamav_mirror_config.yml"
}

variable "clamav_director_config" {
  description = "clamav director configuration file"
  default     = "pas/clamav_director_config.json"
}

variable "clamav_release_url" {
  description = "s3 bucket url for the clamav_release.tgz"
}

variable "clamav_release_sha1" {
  description = "sha1 sum of clamav_release_url"
}
