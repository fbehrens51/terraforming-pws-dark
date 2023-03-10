variable "rds_db_username" {
  default = "admin"
}

variable "rds_instance_class" {
  default = "db.m4.large"
}

variable "engine" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "db_port" {
}

variable "sg_rule_desc" {
}

variable "env_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "subnet_group_name" {
}

variable "kms_key_id" {
}

variable "parameter_group_name" {
  default = null
}

variable "database_name" {
  default = null
}

variable "apply_immediately" {
  type    = bool
  default = true
}

variable "maintenance_window" {
  type    = string
  default = ""
}

variable "backup_window" {
  type    = string
  default = ""
}

variable "database_deletion_protection" {
  type    = bool
  default = true
}
