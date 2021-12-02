variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "terraform_bucket_name" {
}

variable "terraform_region" {
}

variable "singleton_availability_zone" {
}

variable "global_vars" {
  type = any
}

variable "tkgjb_egress_rules" {
  type = list(object({ description = string, port = string, protocol = string, cidr_blocks = string }))
}

variable "tkgjb_ingress_rules" {
  type = list(object({ description = string, port = string, protocol = string, cidr_blocks = string }))
}

variable "availability_zones" {
  type = list(string)
}

variable "internetless" {
}

variable "force_destroy_buckets" {
  type    = bool
  default = false
}
