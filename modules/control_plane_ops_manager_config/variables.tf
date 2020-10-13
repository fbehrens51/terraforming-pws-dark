# ========================
# General Configuration
# ========================

variable "vpc_id" {
  type = string
}

variable "env_name" {
  type        = string
  description = "Identifier for the deployment. This will be used to add an `env` tag to BOSH-deployed VMs"
}

variable "admin_users" {
  type = list(string)
}

variable "concourse_worker_role_name" {
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
# Router Configuration
# ========================

variable "root_domain" {
  description = "The root domain for this environment"
}

variable "uaa_elb_names" {
  type        = list(string)
  description = "List of elb names which UAA should be attached to."
}

variable "web_elb_names" {
  type        = list(string)
  description = "List of elb names which ATC / TSA should be attached to."
}

variable "uaa_cert_pem" {
  type        = string
  description = "Server certificate used by the Control Plane's UAA. Must be valid for uaa.ci.<ROOT_DOMAIN>"
}

variable "ca_certificate" {
  type        = string
  description = "CA certificate used to sign the concourse_cert_pem."
}

variable "uaa_private_key_pem" {
  type        = string
  description = "Server key used by the Control Plane's UAA. Must be valid for uaa.ci.<ROOT_DOMAIN>"
}

variable "concourse_cert_pem" {
  type        = string
  description = "Server certificate used by the Control Plane. Must be valid for *.ci.<ROOT_DOMAIN>"
}

variable "concourse_private_key_pem" {
  type        = string
  description = "Server key used by the Control Plane. Must be valid for *.ci.<ROOT_DOMAIN>"
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
# Infrastructure Configuration
# ========================

variable "secrets_bucket_name" {
}

variable "director_config" {
}

variable "concourse_config" {
}

variable "om_create_db_config" {
}

variable "om_syslog_config" {
}

variable "om_ssl_config" {
}

variable "om_ssh_banner_config" {
}

variable "control_plane_om_server_cert" {
}

variable "control_plane_om_server_key" {
}

variable "singleton_availability_zone" {
  type = string
}

variable "control_plane_subnet_cidrs" {
  type = list(string)
}

variable "control_plane_vpc_dns" {
}

variable "control_plane_subnet_availability_zones" {
  type = list(string)
}

variable "control_plane_subnet_gateways" {
  type = list(string)
}

variable "control_plane_subnet_ids" {
  type = list(string)
}

variable "vms_security_group_id" {
}

variable "ops_manager_ssh_public_key_name" {
}

variable "ops_manager_ssh_private_key" {
}

variable "syslog_host" {
}

variable "syslog_port" {
}

variable "syslog_ca_cert" {
}

variable "volume_encryption_kms_key_arn" {
}

variable "postgres_host" {
}

variable "postgres_port" {
}

variable "postgres_uaa_db_name" {
}

variable "postgres_uaa_username" {
}

variable "postgres_uaa_password" {
}

variable "postgres_db_name" {
}

variable "postgres_username" {
}

variable "postgres_password" {
}

variable "postgres_ca_cert" {
}

variable "mysql_host" {
}

variable "mysql_port" {
}

variable "mysql_db_name" {
}

variable "mysql_username" {
}

variable "mysql_password" {
}

variable "mysql_ca_cert" {
}

variable "control_plane_additional_reserved_ips" { type = map(string) }
