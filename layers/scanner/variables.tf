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

variable "scanner_username" {
  type    = string
  default = "tas_scanner"
}

variable "scanner_password" {
  type = string
}

variable "scanner_package_url" {
  type = string
}


