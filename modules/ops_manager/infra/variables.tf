variable "om_eip" {}

variable "private" {}

variable "env_name" {}

variable "subnet_id" {}

variable "vpc_id" {}

variable "bucket_suffix" {}

variable "tags" {
  type = "map"
}

variable "ingress_rules" {
  type = "list"
}
