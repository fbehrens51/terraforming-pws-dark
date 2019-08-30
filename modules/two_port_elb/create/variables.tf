variable "vpc_id" {}

variable "tags" {
  type = "map"
}

variable "env_name" {}

variable "short_name" {}

variable "internetless" {}

variable "public_subnet_ids" {
  type = "list"
}

variable "egress_cidrs" {
  type = "list"
}

variable "port" {
  type = "string"
}

variable "additional_port" {
  type = "string"
}
