variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "terraform_bucket_name" {
}

variable "promoter_role_arn" {
}

variable "terraform_region" {
}

variable "rds_db_username" {
}

variable "rds_instance_class" {
}

variable "singleton_availability_zone" {
}

variable "global_vars" {
  type = any
}

variable "sjb_egress_rules" {
  type = list(object({ description = string, port = string, protocol = string, cidr_blocks = string }))
}

variable "sjb_ingress_rules" {
  type = list(object({ description = string, port = string, protocol = string, cidr_blocks = string }))
}

variable "availability_zones" {
  type = list(string)
}

variable "internetless" {
}

variable "vpce_interface_prefix" {}

variable "force_destroy_buckets" {
  type    = bool
  default = false
}

variable "control_plane_db_engine" {
  default = "mariadb"
}

variable "control_plane_db_engine_version" {
  default = "10.2"
}