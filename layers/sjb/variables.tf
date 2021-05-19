variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "region" {
}

variable "global_vars" {
  type = any
}

variable "pypi_host" {
}

variable "pypi_host_secure" {
  default = true
}

variable "singleton_availability_zone" {
}

variable "source_artifacts" {
  type    = list
  default = ["pcf-eagle-automation", "terraforming-pws-dark"]
}

variable "cp_target_name" {
  type    = string
  default = "set_this_in_sjb_layer"
}
