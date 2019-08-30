# ========================
# General Configuration
# ========================

variable "vpc_id" {
  type = "string"
}

variable "env_name" {
  type        = "string"
  description = "Identifier for the deployment. This will be used to add an `env` tag to BOSH-deployed VMs"
}

variable "region" {}

variable "custom_ssh_banner_file" {
  type        = "string"
  description = "Custom SSH Banner to be used on launched VMs"
}

variable "security_configuration_trusted_certificates" {
  type = "string"

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
  type        = "string"
  description = "CA Certificate used to sign AWS endpoints, as a PEM encoded string"
}

variable "iaas_configuration_iam_instance_profile" {
  type        = "string"
  description = "IAM Instance Profile used by BOSH to authenticate against AWS"
}

variable "s3_endpoint" {
  type        = "string"
  description = "The s3 endpoint without the protocol/scheme. eg s3.aws.amazonaws.com"
}

variable "ec2_endpoint" {
  type        = "string"
  description = "The ec2 endpoint without the protocol/scheme. eg ec2.us-east-1.aws.amazonaws.com"
}

variable "elb_endpoint" {
  type        = "string"
  description = "The s3 endpoint without the protocol/scheme. eg elasticloadbalancing.us-east-1.aws.amazonaws.com"
}

variable "ntp_servers" {
  type = "list"
}

# ========================
# Router Configuration
# ========================

variable "concourse_domain" {
  description = "The root domain for concourse (uaa, credhub, plane).{concourse_domain}"
}

variable "web_elb_names" {
  type        = "list"
  description = "List of elb names which ATC / TSA should be attached to."
}

variable "uaa_elb_names" {
  type        = "list"
  description = "List of elb names which UAA should be attached to."
}

variable "credhub_elb_names" {
  type        = "list"
  description = "List of elb names which Credhub should be attached to."
}

variable "concourse_cert_pem" {
  type        = "string"
  description = "Server certificate used by the Control Plane. Must be valid for *.ci.<ROOT_DOMAIN>"
}

variable "concourse_private_key_pem" {
  type        = "string"
  description = "Server key used by the Control Plane. Must be valid for *.ci.<ROOT_DOMAIN>"
}

variable "trusted_ca_certs" {
  type        = "string"
  description = "Concatenated CA certificates trusted by Control Plane"
}

# ========================
# SMTP Configuration
# ========================

# Configure the SMTP server that will be used to send notifications.  This
# config section is used by the Bosh director as well as the PAS tile

variable "smtp_recipients" {
  type = "string"
}

variable "smtp_enabled" {
  type = "string"
}

variable "smtp_domain" {
  type = "string"
}

variable "smtp_host" {
  type = "string"
}

variable "smtp_user" {
  type = "string"
}

variable "smtp_password" {
  type = "string"
}

variable "smtp_tls" {
  type = "string"
}

variable "smtp_from" {
  type = "string"
}

variable "smtp_port" {
  type = "string"
}

# ========================
# Infrastructure Configuration
# ========================

variable "singleton_availability_zone" {
  type = "string"
}

variable "control_plane_subnet_cidrs" {
  type = "list"
}

variable "control_plane_vpc_dns" {}

variable "control_plane_subnet_availability_zones" {
  type = "list"
}

variable "control_plane_subnet_gateways" {
  type = "list"
}

variable "control_plane_subnet_ids" {
  type = "list"
}

variable "vms_security_group_id" {}

variable "ops_manager_ssh_public_key_name" {}

variable "ops_manager_ssh_private_key" {}

variable "pivnet_api_token" {}

variable "product_blobs_s3_bucket" {}

variable "product_blobs_s3_region" {}

variable "product_blobs_s3_endpoint" {}

variable "s3_access_key_id" {}

variable "s3_secret_access_key" {}

variable "s3_auth_type" {}
