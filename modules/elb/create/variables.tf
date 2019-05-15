
variable "vpc_id" {}

variable "tags" {
  type = "map"
}

variable "env_name" {}

variable "internetless" {}

variable "public_subnet_ids" {
  type = "list"
}

variable "egress_cidrs" {
  type = "list"
}

variable "ops_manager_instance_id" {}
