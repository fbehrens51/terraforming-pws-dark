variable "pas_subnet_cidrs" {
  type = "list"
}

variable "rds_address" {
}

variable "rds_password" {
}

variable "rds_port" {
}

variable "rds_username" {
}

variable "redis_host" {
}

variable "redis_password" {
}

variable "pas_bucket_iam_instance_profile_name" {
}

variable "pas_buildpacks_bucket" {
}

variable "pas_droplets_bucket" {
}

variable "pas_packages_bucket" {
}

variable "pas_resources_bucket" {
}

variable "pas_subnet_availability_zones" {
  type = "list"
}

variable "pas_subnet_gateways" {
  type = "list"
}

variable "pas_subnet_ids" {
  type = "list"
}

variable "vms_security_group_id" {
}

variable "region" {
}

variable "ops_manager_ssh_public_key_name" {
}

variable "ops_manager_ssh_private_key" {
}

variable "s3_endpoint" {
}
