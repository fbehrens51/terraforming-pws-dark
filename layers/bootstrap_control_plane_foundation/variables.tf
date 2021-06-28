variable "remote_state_bucket" {
}

variable "remote_state_region" {
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

variable "availability_zones" {
  type = list(string)
}

variable "internetless" {
}

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