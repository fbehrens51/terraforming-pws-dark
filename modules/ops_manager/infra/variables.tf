variable "om_eip" {
}

variable "private" {
}

variable "env_name" {
}

variable "subnet_id" {
}

variable "vpc_id" {
}

variable "bucket_suffix" {
}

variable "bucket_suffix_name" {
}

variable "tags" {
  type = map(string)
}

variable "ingress_rules" {
  type = list(object({ description = string, port = string, protocol = string, cidr_blocks = string }))
}

variable "s3_logs_bucket" {}

variable "force_destroy_buckets" {
  type    = bool
  default = false
}
