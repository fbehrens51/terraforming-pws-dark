variable "remote_state_bucket" {}
variable "remote_state_region" {}
variable "env_name" {}

variable "tags" {
  type = "map"
}

variable "splunk_rpm_version" {}
variable "splunk_rpm_s3_bucket" {}
variable "splunk_rpm_s3_region" {}

variable "instance_type" {
  default = "t2.small"
}

variable "license_path" {}
