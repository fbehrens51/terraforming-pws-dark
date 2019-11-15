variable "remote_state_bucket" {}
variable "remote_state_region" {}

variable "user_data_path" {}
variable "instance_type" {}

variable "region" {}

variable "tags" {
  type = "map"
}

variable "pypi_host" {}

variable "pypi_host_secure" {
  default = true
}
