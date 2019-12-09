variable "env_name" {
  type = "string"
}

variable "availability_zones" {
  type = "list"
}

variable "vpc_id" {
  type = "string"
}

variable "route_table_ids" {
  type = "list"
}

variable "public_subnet_ids" {
  type = "list"
}

variable "bucket_suffix" {
  type = "string"
}

variable "zone_id" {
  type = "string"
}

variable "dns_suffix" {
  type = "string"
}

variable "create_backup_pas_buckets" {
  default = false
}

variable "create_versioned_pas_buckets" {
  default = false
}

variable "create_isoseg_resources" {
  default = 0
}

variable "tags" {
  type = "map"
}

module "cidr_lookup" {
  source   = "../calculate_subnets"
  vpc_cidr = "${data.aws_vpc.vpc.cidr_block}"
}

locals {
  pas_cidrs     = "${module.cidr_lookup.pas_cidrs}"
  services_cidr = "${module.cidr_lookup.services_cidr}"
}
