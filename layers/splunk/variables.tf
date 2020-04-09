variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "env_name" {
}

variable "tags" {
  type = map(string)
}

variable "splunk_rpm_version" {
}

variable "region" {
}

variable "instance_type" {
  default = "m5.large"
}

variable "internetless" {
}
