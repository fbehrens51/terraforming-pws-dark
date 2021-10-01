variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "region" {
}

variable "global_vars" {
  type = any
}

variable "reserved_ip" {
  type    = string
  default = ""
}

variable "subnet_id" {
  type    = string
  default = ""
}

variable "internetless" {
  type = bool
}


