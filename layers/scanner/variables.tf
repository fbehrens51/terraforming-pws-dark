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

variable "network_name" {
  type    = string
  default = ""
}

variable "ntp_server" {
  type    = string
  default = "169.254.169.123"
}

variable "group_name" {
  type    = string
  default = "users:TWSG"
}

variable "user_name" {
  type    = string
  default = "fbehrens@vmware.com"
}


