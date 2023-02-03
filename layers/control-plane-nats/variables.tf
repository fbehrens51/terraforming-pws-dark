variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "global_vars" {
  type = any
}

variable "internetless" {
}

variable "nat_log_new_connections" {
  type    = bool
  default = false
}
