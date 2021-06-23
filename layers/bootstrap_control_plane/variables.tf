variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "terraform_region" {
}

variable "global_vars" {
  type = any
}

variable "availability_zones" {
  type = list(string)
}

variable "internetless" {
}

variable "vpce_interface_prefix" {}


