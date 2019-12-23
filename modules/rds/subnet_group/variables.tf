variable "env_name" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "cidr_block" {
}

