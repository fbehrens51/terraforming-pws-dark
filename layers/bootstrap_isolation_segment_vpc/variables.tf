
variable "vpc_id" {}

variable "availability_zones" {
  type = list(string)
}

variable "isolation_segment_name_0" {}
variable "isolation_segment_name_1" {}
variable "isolation_segment_name_2" {}
variable "isolation_segment_name_3" {}

variable "global_vars" {
  type = any
}

variable "internetless" {
  type = bool
}

variable "remote_state_bucket" {}
variable "remote_state_region" {}

variable "nat_log_new_connections" {
  type    = bool
  default = false
}
