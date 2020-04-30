variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "singleton_availability_zone" {
}

variable "smtp_from" {
}

variable "smtp_recipients" {
}

variable "smtp_domain" {
}

variable "smtp_enabled" {
}

variable "iaas_configuration_endpoints_ca_cert" {
}

variable "env_name" {
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

variable "tags" {
  type = map(string)
}

variable "availability_zones" {
  type = list(string)
}

variable "clamav_external_mirrors" {
  description = "This option is only relevant when `clamav_no_upstream_mirror` is set to false.  A list of external mirrors to use.  If empty, the official mirror will be used."
  type        = list(string)
}

variable "clamav_mirror_instance_type" {
  default = "automatic"
}

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
  default     = "control_plane/om_syslog_config.json"
}

variable "om_ssl_config" {
  description = "om ssl configuration file"
  default     = "control_plane/om_ssl_config.json"
}

variable "om_ssh_banner_config" {
  description = "om ssh_banner configuration file"
  default     = "control_plane/om_ssh_banner_config.json"
}

variable "director_config" {
  default = "control_plane/director_config.yml"
}

variable "concourse_config" {
  default = "control_plane/concourse_config.yml"
}

variable "runtime_config" {
  default = "control_plane/runtime_config_config.yml"
}

variable "clamav_addon_config" {
  default = "control_plane/clamav_addon_config.yml"
}

variable "clamav_mirror_config" {
  default = "control_plane/clamav_mirror_config.yml"
}

