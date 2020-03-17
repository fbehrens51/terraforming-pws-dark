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

variable "env_name" {
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

variable "backup_restore_instance_type" {
  default = "automatic"
}

variable "clock_global_instance_type" {
  default = "automatic"
}

variable "cloud_controller_instance_type" {
  default = "automatic"
}

variable "cloud_controller_worker_instance_type" {
  default = "automatic"
}

variable "consul_server_instance_type" {
  default = "automatic"
}

variable "credhub_instance_type" {
  default = "automatic"
}

variable "diego_brain_instance_type" {
  default = "automatic"
}

variable "diego_cell_instance_type" {
  default = "automatic"
}

variable "diego_database_instance_type" {
  default = "automatic"
}

variable "doppler_instance_type" {
  default = "automatic"
}

variable "ha_proxy_instance_type" {
  default = "automatic"
}

variable "loggregator_trafficcontroller_instance_type" {
  default = "automatic"
}

variable "mysql_instance_type" {
  default = "automatic"
}

variable "mysql_monitor_instance_type" {
  default = "automatic"
}

variable "mysql_proxy_instance_type" {
  default = "automatic"
}

variable "nats_instance_type" {
  default = "automatic"
}

variable "nfs_server_instance_type" {
  default = "automatic"
}

variable "router_instance_type" {
  default = "automatic"
}

variable "syslog_adapter_instance_type" {
  default = "automatic"
}

variable "syslog_scheduler_instance_type" {
  default = "automatic"
}

variable "tcp_router_instance_type" {
  default = "automatic"
}

variable "uaa_instance_type" {
  default = "automatic"
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

