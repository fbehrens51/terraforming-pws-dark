variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "singleton_availability_zone" {
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

variable "global_vars" {
  type = any
}

variable "internetless" {
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

variable "availability_zones" {
  type = list(string)
}

variable "clamav_external_mirrors" {
  description = "This option is only relevant when `clamav_no_upstream_mirror` is set to false.  A list of external mirrors to use.  If empty, the official mirror will be used."
  type        = list(string)
}

variable "admin_users" {
  description = "List of usernames that will be given admin privileges."
  type        = list(string)
}

variable "om_create_db_config" {
  description = "om create_db configuration file"
  default     = "control_plane/om_create_db_config.bash"
}

variable "om_syslog_config" {
  description = "om syslog configuration file"
  default     = "control_plane/om_syslog_config.yml"
}

variable "om_uaa_password_policy_config" {
  description = "om uaa password policy configuration file"
  default     = "control_plane/om_uaa_password_policy_config.json"
}

variable "om_tokens_expiration_config" {
  description = "om tokens_expiration configuration file"
  default     = "control_plane/om_tokens_expiration_config.yml"
}

variable "om_ssl_config" {
  description = "om ssl configuration file"
  default     = "control_plane/om_ssl_config.yml"
}

variable "om_ssh_banner_config" {
  description = "om ssh_banner configuration file"
  default     = "control_plane/om_ssh_banner_config.yml"
}

variable "director_config" {
  description = "bosh director configuration file"
  default     = "control_plane/director_config.yml"
}

variable "concourse_config" {
  description = "concourse configuration file"
  default     = "control_plane/concourse_config.yml"
}

variable "worker_config" {
  description = "concourse worker configuration file"
  default     = "control_plane/worker_config.yml"
}

variable "runtime_config" {
  description = "runtime configuration file"
  default     = "control_plane/runtime_config_tile_config.yml"
}

variable "clamav_addon_config" {
  description = "clamav addon configuration file"
  default     = "control_plane/clamav_addon_tile_config.yml"
}

variable "clamav_mirror_config" {
  description = "clamav mirror configuration file"
  default     = "control_plane/clamav_mirror_config.yml"
}

variable "clamav_director_config" {
  description = "clamav director configuration file"
  default     = "control_plane/clamav_director_config.json"
}

variable "clamav_release_url" {
  description = "s3 bucket url for the clamav_release.tgz"
}

variable "clamav_release_sha1" {
  description = "sha1 sum of clamav_release_url"
}

variable "password_policies_expires_after_months" {
  type    = string
  default = "0"
}

variable "password_policies_max_retry" {
  type    = string
  default = "5"
}

variable "password_policies_min_length" {
  type    = string
  default = "0"
}

variable "password_policies_min_lowercase" {
  type    = string
  default = "0"
}

variable "password_policies_min_numeric" {
  type    = string
  default = "0"
}

variable "password_policies_min_special" {
  type    = string
  default = "0"
}

variable "password_policies_min_uppercase" {
  type    = string
  default = "0"
}

variable "disk_type" {
  description = "disk type to use for bosh VMs"
  type        = string
  default     = "gp2"
}
