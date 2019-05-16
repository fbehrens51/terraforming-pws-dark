variable "env_name" {}

variable "om_eip" {
  default = true
  description = "Creates an EIP for OM"
}

variable "om_eni" {
  default = false
  description = "Creates an ENI for OM"
}

variable "om_public_subnet" {
  default = true
  description = "if true puts the OM instance in the public subnet. If false, puts it in the infra subnet."
}


variable "use_tcp_routes" {
  default = true
  description = "Indicate whether or not to enable tcp routes and elbs"
}

variable "use_ssh_routes" {
  default = true
  description = "Indicate whether or not to enable ssh routes and elbs"
}

variable "dns_suffix" {}

variable "hosted_zone" {
  default = ""
}

variable "availability_zones" {
  type = "list"
}

variable "vpc_cidr" {
  type    = "string"
  default = "10.0.0.0/16"
}

variable "vpc_id" {
  description = "pre-exsting VPC ID"
}

variable "use_route53" {
  default = true
  description = "Indicate whether or not to enable route53"
}

/******
* PAS *
*******/

variable "internetless" {
  default = false
}

variable "create_versioned_pas_buckets" {
  default = false
}

variable "create_backup_pas_buckets" {
  default = false
}

variable "kms_key_name" {
  description = "the name of the kms key that will be used for our pas buckets"
}

variable "pas_bucket_role_arn" {}

/****************
* Ops Manager *
*****************/

variable "ops_manager_ami" {
  default = ""
}

variable "optional_ops_manager_ami" {
  default = ""
}

variable "ops_manager_instance_type" {
  default = "r4.large"
}

variable "ops_manager_private" {
  default     = false
  description = "If true, the Ops Manager will be colocated with the BOSH director on the infrastructure subnet instead of on the public subnet"
}

variable "ops_manager_vm" {
  default = true
}

variable "optional_ops_manager" {
  default = false
}

variable ops_manager_role_name {
  description = "the role name used for the opsman controlled bosh director"
}

variable pas_bucket_role_name {
  description = "the role name used by pas for access to s3 buckets"
}

/******
* RDS *
*******/

variable "rds_db_username" {
  default = "admin"
}

variable "rds_instance_class" {
  default = "db.m4.large"
}

variable "rds_instance_count" {
  type    = "string"
  default = 0
}

variable "ssl_cert" {
  type        = "string"
  description = "the contents of an SSL certificate to be used by the LB, optional if `ssl_ca_cert` is provided"
  default     = ""
}

variable "ssl_private_key" {
  type        = "string"
  description = "the contents of an SSL private key to be used by the LB, optional if `ssl_ca_cert` is provided"
  default     = ""
}

variable "ssl_ca_cert" {
  type        = "string"
  description = "the contents of a CA public key to be used to sign the generated LB certificate, optional if or `ssl_cert` is provided"
  default     = ""
}

variable "ssl_ca_private_key" {
  type        = "string"
  description = "the contents of a CA private key to be used to sign the generated LB certificate, optional if or `ssl_cert` is provided"
  default     = ""
}

/*****************************
 * Isolation Segment Options *
 *****************************/

variable "isoseg_ssl_cert" {
  type        = "string"
  description = "the contents of an SSL certificate to be used by the LB, optional if `isoseg_ssl_ca_cert` is provided"
  default     = ""
}

variable "isoseg_ssl_private_key" {
  type        = "string"
  description = "the contents of an SSL private key to be used by the LB, optional if `isoseg_ssl_ca_cert` is provided"
  default     = ""
}

variable "isoseg_ssl_ca_cert" {
  type        = "string"
  description = "the contents of a CA public key to be used to sign the generated iso seg LB certificate, optional if `isoseg_ssl_cert` is provided"
  default     = ""
}

variable "isoseg_ssl_ca_private_key" {
  type        = "string"
  description = "the contents of a CA private key to be used to sign the generated iso seg LB certificate, optional if `isoseg_ssl_cert` is provided"
  default     = ""
}

/********
 * Tags *
 *********/

variable "tags" {
  type        = "map"
  default     = {}
  description = "Key/value tags to assign to all AWS resources"
}

/**************
 * Deprecated *
 ***************/

variable "create_isoseg_resources" {
  type        = "string"
  default     = "0"
  description = "Optionally create a LB and DNS entries for a single isolation segment. Valid values are 0 or 1."
}
