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
  default = "mysql"
}

variable "control_plane_db_engine_version" {
  default = "5.7"
}

variable "concourse_postgres_maintenance_window" {
  type    = string
  default = "Sun:08:00-Sun:08:30"
}

variable "concourse_postgres_backup_window" {
  type    = string
  default = "10:00-10:30"
}
