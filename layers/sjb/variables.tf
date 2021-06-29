variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "region" {
}

variable "global_vars" {
  type = any
}

variable "pypi_host" {
}

variable "pypi_host_secure" {
  default = true
}

variable "singleton_availability_zone" {
}

variable "cp_target_name" {
  type = string
}

variable "git_host" {
  type = string
}

variable "env_repo_name" {
  type = string
}

variable "credhub_vars_name" {
  type = string
}

variable "endpoint_domain" {
  type = string
}
