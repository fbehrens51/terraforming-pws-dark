variable "region" {}
variable "remote_state_bucket" {}
variable "remote_state_region" {}
variable "singleton_availability_zone" {}
variable "system_domain" {}
variable "apps_domain" {}
variable "cloud_controller_encrypt_key_secret" {}
variable "credhub_encryption_password" {}
variable "router_cert_pem_file" {}
variable "router_private_key_pem_file" {}
variable "router_trusted_ca_certificates_file" {}
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
variable "uaa_service_provider_key_credentials_cert_pem_file" {}
variable "uaa_service_provider_key_credentials_private_key_pem_file" {}
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
variable "security_configuration_trusted_certificates" {}
variable "rds_ca_cert_file" {}
variable "jwt_expiration" {}
variable "ldap_tls_ca_cert_file" {}
variable "ldap_tls_client_cert_file" {}
variable "ldap_tls_client_key_file" {}
variable "smoke_test_client_cert_file" {}
variable "smoke_test_client_key_file" {}
variable "ldap_basedn" {}
variable "ldap_dn" {}
variable "ldap_password" {}
variable "ldap_host" {}
variable "ldap_port" {}
variable "ldap_role_attr" {}
variable "redis_ca_cert_file" {}
variable "env_name" {}
variable "internetless" {}
variable "s3_endpoint" {}
variable "ec2_endpoint" {}
variable "elb_endpoint" {}
variable "pivnet_api_token" {}
variable "pas_tile_s3_bucket" {}

variable "ntp_servers" {
  type = "list"
}

variable "tags" {
  type = "map"
}

variable "availability_zones" {
  type = "list"
}
