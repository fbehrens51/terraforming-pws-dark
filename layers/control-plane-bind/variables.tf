variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "global_vars" {
  type = any
}

variable "internetless" {
}

variable "internet" {
  default     = false
  description = "if true, applies extra rules to iptables on the bind servers to prevent participation in distributed DNS amplification attacks"
}

variable "endpoint_domain" {
  type = string
}