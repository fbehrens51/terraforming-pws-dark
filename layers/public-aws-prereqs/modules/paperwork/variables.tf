variable "env_name" {
  type = "string"
}

variable "director_role_name" {}

variable "bucket_role_name" {}

variable "worker_role_name" {}

variable "splunk_role_name" {}

variable "key_manager_role_name" {}
variable "root_domain" {}

variable "users" {
  type = "list"
}
