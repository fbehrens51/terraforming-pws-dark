# ========================
# General Configuration
# ========================

variable "pas_vpc_dns" {
  type = string
}

variable "env_name" {
  type        = string
  description = "Identifier for the deployment. This will be used to add an `env` tag to BOSH-deployed VMs"
}

variable "apps_domain" {
  type        = string
  description = "This domain should resolve to the PAS ELB and is used for deployed applications"
}

variable "system_domain" {
  type        = string
  description = "This domain should resolve to the PAS ELB and is used for internal system components"
}

variable "region" {
}

variable "custom_ssh_banner" {
  type        = string
  description = "Custom SSH Banner to be used on launched VMs"
}

variable "security_configuration_trusted_certificates" {
  type = string

  description = <<EOF
  A concatenated list of trusted certificates that will be trusted by all
  deployed VMs
  - the CA used to sign the router cert
  - the CA used to sign the AWS endpoints
EOF

}

variable "cloud_controller_encrypt_key_secret" {
  type        = string
  description = "Secret used to encrypt data by the cloud controller"
}

variable "credhub_encryption_password" {
  type        = string
  description = "Secret used to encrypt data in credhub"
}

# ========================
# Portal Configuration
# ========================

variable "ldap_tls_ca_cert" {
  type = string
}

variable "ldap_tls_client_cert" {
  type = string
}

variable "ldap_tls_client_key" {
  type = string
}

variable "ldap_basedn" {
  type        = string
  description = "LDAP basedn for portal to search for users users"
}

variable "ldap_dn" {
  type        = string
  description = "LDAP credentials for portal to connect"
}

variable "ldap_password" {
  type        = string
  description = "LDAP credentials for portal to connect"
}

variable "ldap_host" {
  type = string
}

variable "ldap_port" {
  type = string
}

variable "ldap_role_attr" {
  type        = string
  description = "Name of the LDAP attribute which has user permissions"
}

variable "smoke_test_client_cert" {
  type        = string
  description = "Client certificate used by smoke test to login.  The certificate must be present in LDAP"
}

variable "smoke_test_client_key" {
  type        = string
  description = "Client key used by smoke test to login.  The key must be present in LDAP"
}

# ========================
# IAAS Configuration
# ========================

variable "iaas_configuration_endpoints_ca_cert" {
  type        = string
  description = "CA Certificate used to sign AWS endpoints, as a PEM encoded string"
}

variable "iaas_configuration_iam_instance_profile" {
  type        = string
  description = "IAM Instance Profile used by BOSH to authenticate against AWS"
}

variable "s3_endpoint" {
  type        = string
  description = "The s3 endpoint without the protocol/scheme. eg s3.aws.amazonaws.com"
}

variable "ec2_endpoint" {
  type        = string
  description = "The ec2 endpoint without the protocol/scheme. eg ec2.us-east-1.aws.amazonaws.com"
}

variable "elb_endpoint" {
  type        = string
  description = "The s3 endpoint without the protocol/scheme. eg elasticloadbalancing.us-east-1.aws.amazonaws.com"
}

variable "ntp_servers" {
  type = list(string)
}

# ========================
# UAA Configuration
# ========================

variable "uaa_service_provider_key_credentials_cert_pem" {
  type        = string
  description = "Server certificate presented by UAA during authentication. Should be valid for login.<SYSTEM_DOMAIN>"
}

variable "uaa_service_provider_key_credentials_private_key_pem" {
  type        = string
  description = "Server key presented by UAA during authentication. Must be valid for login.<SYSTEM_DOMAIN>"
}

variable "password_policies_expires_after_months" {
  type = string
}

variable "password_policies_max_retry" {
  type = string
}

variable "password_policies_min_length" {
  type = string
}

variable "password_policies_min_lowercase" {
  type = string
}

variable "password_policies_min_numeric" {
  type = string
}

variable "password_policies_min_special" {
  type = string
}

variable "password_policies_min_uppercase" {
  type = string
}

# ========================
# Router Configuration
# ========================

variable "router_elb_names" {
  type        = list(string)
  description = "List of elb names which GoRouter should be attached to."
}

variable "vanity_cert_enabled" {
  type        = string
  description = "String boolean to include the vanity certificate in the CF configuration"
}

variable "vanity_cert_pem" {
  type        = string
  description = "Server certificate used by the GoRouter. Must be valid for *.<VANITY_DOMAIN>"
}

variable "vanity_private_key_pem" {
  type        = string
  description = "Server key used by the GoRouter. Must be valid for *.<VANITY_DOMAIN>"
}

variable "router_cert_pem" {
  type        = string
  description = "Server certificate used by the GoRouter. Must be valid for *.<SYSTEM_DOMAIN> and *.<APPS_DOMAIN>"
}

variable "router_private_key_pem" {
  type        = string
  description = "Server key used by the GoRouter. Must be valid for *.<SYSTEM_DOMAIN> and *.<APPS_DOMAIN>"
}

variable "router_trusted_ca_certificates" {
  type        = string
  description = "Concatenated CA certificates trusted by GoRouter. This certificate controls which client certs will be allowed to attempt authentication via Portal"
}

# ========================
# Errand Configuration
# ========================

variable "errands_deploy_autoscaler" {
  type = string
}

variable "errands_deploy_notifications" {
  type = string
}

variable "errands_deploy_notifications_ui" {
  type = string
}

variable "errands_metric_registrar_smoke_test" {
  type = string
}

variable "errands_nfsbrokerpush" {
  type = string
}

variable "errands_push_apps_manager" {
  type = string
}

variable "errands_push_usage_service" {
  type = string
}

variable "errands_smbbrokerpush" {
  type = string
}

variable "errands_smoke_tests" {
  type = string
}

variable "errands_test_autoscaling" {
  type = string
}

# ========================
# SMTP Configuration
# ========================

# Configure the SMTP server that will be used to send notifications.  This
# config section is used by the Bosh director as well as the PAS tile

variable "smtp_recipients" {
  type = string
}

variable "smtp_enabled" {
  type = string
}

variable "smtp_domain" {
  type = string
}

variable "smtp_host" {
  type = string
}

variable "smtp_user" {
  type = string
}

variable "smtp_password" {
  type = string
}

variable "smtp_tls" {
  type = string
}

variable "smtp_from" {
  type = string
}

variable "smtp_port" {
  type = string
}

# ========================
# Branding Configuration
# ========================

variable "apps_manager_global_wrapper_footer_content" {
  type        = string
  description = "The classification footer displayed in apps manager"
}

variable "apps_manager_global_wrapper_header_content" {
  type        = string
  description = "The classification header displayed in apps manager"
}

variable "apps_manager_footer_text" {
  type = string
}

variable "apps_manager_accent_color" {
  type        = string
  description = "A Hex color, eg '#ff0000'"
}

variable "apps_manager_global_wrapper_text_color" {
  type        = string
  description = "A Hex color, eg '#ff0000'"
}

variable "apps_manager_company_name" {
  type = string
}

variable "apps_manager_global_wrapper_bg_color" {
  type        = string
  description = "A Hex color, eg '#ff0000'"
}

variable "apps_manager_favicon_file" {
  type        = string
  description = "Path to a PNG file"
}

variable "apps_manager_square_logo_file" {
  type        = string
  description = "Path to a PNG file"
}

variable "apps_manager_main_logo_file" {
  type        = string
  description = "Path to a PNG file"
}

variable "apps_manager_tools_url" {
  type        = string
  description = "URL to allow users to download tools (eg cf cli)"
}

# ========================
# Infrastructure Configuration
# ========================

variable "secrets_bucket_name" {
}

variable "om_create_db_config" {
}

variable "om_drop_db_config" {
  default = null
}

variable "om_syslog_config" {
}

variable "om_ssl_config" {
}

variable "om_ssh_banner_config" {
}

variable "om_server_cert" {
}

variable "om_server_key" {
}

variable "cf_config" {
}

variable "cf_tools_config" {
}

variable "director_config" {
}

variable "portal_config" {
}

variable "singleton_availability_zone" {
  type = string
}

variable "rds_address" {
}

variable "rds_password" {
}

variable "rds_port" {
}

variable "rds_username" {
}

variable "rds_ca_cert_pem" {
  type        = string
  description = "CA Cert which signs the rds server certificate."
}

variable "blobstore_instance_profile" {
  type        = string
  description = "An IAM Instance profile which permission to read and write to the buckets specified below"
}

variable "volume_encryption_kms_key_arn" {
}

variable "kms_key_id" {
}

variable "pas_buildpacks_backup_bucket" {
}

variable "pas_droplets_backup_bucket" {
}

variable "pas_packages_backup_bucket" {
}

variable "pas_resources_backup_bucket" {
}

variable "pas_buildpacks_bucket" {
}

variable "pas_droplets_bucket" {
}

variable "pas_packages_bucket" {
}

variable "pas_resources_bucket" {
}

variable "isolation_segment_to_subnets" {
  type = map(list(object({
    id                = string,
    cidr_block        = string,
    availability_zone = string,
  })))
}

variable "isolation_segment_to_security_groups" {
  type = map(object({
    name = string,
  }))
}

variable "pas_subnet_cidrs" {
  type = list(string)
}

variable "pas_subnet_availability_zones" {
  type = list(string)
}

variable "pas_subnet_gateways" {
  type = list(string)
}

variable "pas_subnet_ids" {
  type = list(string)
}

variable "infrastructure_subnet_cidrs" {
  type = list(string)
}

variable "infrastructure_subnet_availability_zones" {
  type = list(string)
}

variable "infrastructure_subnet_gateways" {
  type = list(string)
}

variable "infrastructure_subnet_ids" {
  type = list(string)
}

variable "vms_security_group_id" {
}

variable "ops_manager_ssh_public_key_name" {
}

variable "ops_manager_ssh_private_key" {
}

variable "mirror_bucket_name" {
}

variable "splunk_syslog_host" {
}

variable "splunk_syslog_port" {
}

variable "splunk_syslog_ca_cert" {
}

variable "backup_restore_instance_type" {
}

variable "clock_global_instance_type" {
}

variable "cloud_controller_instance_type" {
}

variable "cloud_controller_worker_instance_type" {
}

variable "consul_server_instance_type" {
}

variable "credhub_instance_type" {
}

variable "diego_brain_instance_type" {
}

variable "diego_cell_instance_type" {
}

variable "diego_database_instance_type" {
}

variable "doppler_instance_type" {
}

variable "ha_proxy_instance_type" {
}

variable "loggregator_trafficcontroller_instance_type" {
}

variable "mysql_instance_type" {
}

variable "mysql_monitor_instance_type" {
}

variable "mysql_proxy_instance_type" {
}

variable "nats_instance_type" {
}

variable "nfs_server_instance_type" {
}

variable "router_instance_type" {
}

variable "syslog_adapter_instance_type" {
}

variable "syslog_scheduler_instance_type" {
}

variable "tcp_router_instance_type" {
}

variable "uaa_instance_type" {
}

