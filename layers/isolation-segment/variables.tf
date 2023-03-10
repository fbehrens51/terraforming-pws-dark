variable "name" {
  description = "Cannot be longer than 10 characters.  The name will be used to derive the placement tag by replacing spaces with underscores and lowercasing the entire string.  The placement tag is available in the placement_tag output."
}

variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "singleton_availability_zone" {
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
