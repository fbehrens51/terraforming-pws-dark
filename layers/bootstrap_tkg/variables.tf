// Shared
variable "availability_zones" {
  type = list(string)
}

variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "global_vars" {
  type = any
}

// Unique
variable "tkg_cluster_name" {
}
