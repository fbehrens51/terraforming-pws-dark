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
