variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "instance_type" {
}

variable "region" {
}

variable "tags" {
  type = map(string)
}

variable "pypi_host" {
}

variable "pypi_host_secure" {
  default = true
}

variable "internetless" {
}

