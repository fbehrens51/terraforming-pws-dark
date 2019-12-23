variable "vpc_id" {
}

variable "tags" {
  type = map(string)
}

variable "env_name" {
}

variable "short_name" {
}

variable "internetless" {
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "egress_cidrs" {
  type = list(string)
}

variable "port" {
  default = 443
}

variable "instance_port" {
  default = ""
}

variable "health_check" {
  default = ""
}

