
variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "singleton_availability_zone" {
}

variable "vanity_cert_enabled" {
}

variable "global_vars" {
  type = any
}

variable "instance_type" {
  type = string
  default = ""
}

variable "instance_count" {
  type = number
  default = 5
}