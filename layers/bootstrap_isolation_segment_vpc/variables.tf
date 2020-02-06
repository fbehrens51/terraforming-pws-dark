
variable "vpc_id" {}

variable "availability_zones" {
  type = list(string)
}

variable "isolation_segment_name_0" {}
variable "isolation_segment_name_1" {}
variable "isolation_segment_name_2" {}
variable "isolation_segment_name_3" {}

variable "tags" {
  type = map(string)
}

variable "internetless" {
  type = bool
}

variable "nat_instance_type" {}
variable "remote_state_bucket" {}
variable "remote_state_region" {}
