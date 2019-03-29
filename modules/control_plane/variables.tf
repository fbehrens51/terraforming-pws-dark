variable "vpc_id" {
  type = "string"
}

variable "env_name" {
  type = "string"
}

variable "availability_zones" {
  type = "list"
}

variable "zone_id" {
  type = "string"
}

variable "use_route53" {
}

variable "dns_suffix" {
  type = "string"
}

variable "public_subnet_ids" {
  type = "list"
}

variable "private_route_table_ids" {
  type = "list"
}

variable "tags" {
  type = "map"
}

module "cidr_lookup" {
  source = "../calculate_subnets"
  vpc_cidr = "${data.aws_vpc.vpc.cidr_block}"
}

locals {
  control_plane_cidr = "${module.cidr_lookup.control_plane_cidr}"
}
