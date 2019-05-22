variable "vpc_id" {}

variable "availability_zones" {
  type = "list"
}

variable "tags" {
  type    = "map"
  default = {}
}

variable "env_name" {}

module "cidr_lookup" {
  source   = "../calculate_subnets"
  vpc_cidr = "${data.aws_vpc.vpc.cidr_block}"
}

locals {
  portal_cache_cidr = "${module.cidr_lookup.portal_cache_cidr}"
}
