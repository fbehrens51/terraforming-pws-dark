variable "env_name" {
  type = string
}

variable "director_role_name" {
}

variable "bucket_role_name" {
}

variable "worker_role_name" {
}

variable "archive_role_name" {
}

variable "splunk_role_name" {
}

variable "tsdb_role_name" {
}

variable "root_domain" {
}

variable "ldap_eip" {
}

variable "users" {
  type = list(object({ name = string, username = string, roles = string }))
}

