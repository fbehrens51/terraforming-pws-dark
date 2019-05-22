variable "rds_db_username" {
  default = "admin"
}

variable "rds_instance_class" {
  default = "db.m4.large"
}

variable "engine" {
  type = "string"
}

variable "engine_version" {
  type = "string"
}

variable "db_port" {}

variable "rds_instance_count" {
  type    = "string"
  default = 0
}

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

module "cidr_lookup" {
  source   = "../calculate_subnets"
  vpc_cidr = "${data.aws_vpc.vpc.cidr_block}"
}

locals {
  rds_cidr = "${module.cidr_lookup.rds_cidr}"
}
