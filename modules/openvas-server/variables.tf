variable "env_name" {
  type = "string"
}

variable "vm_name" {
  type    = "string"
  default = "OpenVAS Server"
}

variable "ami_id" {
  type    = "string"
  default = "ami-0a313d6098716f372"
}

variable "route_table_id" {
  type = "string"
}

variable "instance_type" {
  type    = "string"
  default = "m4.2xlarge"
}

variable "openvas_elb_name" {
  type = "string"
}
