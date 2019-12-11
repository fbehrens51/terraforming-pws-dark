variable "env_name" {
  type = "string"
}

variable "availability_zones" {
  type = "list"
}

variable "vpc_id" {
  type = "string"
}

variable "tags" {
  type = "map"
}

variable "cidr_block" {}
