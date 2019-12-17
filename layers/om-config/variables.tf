variable "remote_state_bucket" {}
variable "remote_state_region" {}
variable "singleton_availability_zone" {}
variable "cloud_controller_encrypt_key_secret" {}
variable "credhub_encryption_password" {}
variable "smtp_host" {}
variable "smtp_user" {}
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
variable "jwt_expiration" {}
variable "env_name" {}
variable "s3_endpoint" {}
variable "ec2_endpoint" {}
variable "elb_endpoint" {}
variable "pivnet_api_token" {}
variable "region" {}
variable "portal_product_version" {}
variable "runtime_config_product_version" {}
variable "cf_tools_product_version" {}
variable "ipsec_log_level" {}
variable "ipsec_optional" {}

variable "apps_manager_tools_url" {
  description = "The CF CLI tools url.  Defaults to cli.<system_domain>"
  default     = ""
}

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
