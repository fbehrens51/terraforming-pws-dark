variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "instance_type" {
  default = "m5.2xlarge"
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

