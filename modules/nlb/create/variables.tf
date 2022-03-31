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
  default = null
}

variable "health_check_path" {
  default = null
}

variable "health_check_port" {
  default = null
}

variable "health_check_proto" {
  default = "TCP"
}
variable "health_check_cidr_blocks" {
  default = null
}
variable "preserve_client_ip" {
  type    = bool
  default = true
}
