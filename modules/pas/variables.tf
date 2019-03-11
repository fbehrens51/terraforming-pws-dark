variable "env_name" {
  type = "string"
}

variable "region" {
  type = "string"
}

variable "availability_zones" {
  type = "list"
}

variable "vpc_cidr" {
  type = "string"
}

variable "vpc_id" {
  type = "string"
}

variable "use_tcp_routes" {}

variable "use_ssh_routes" {}

variable "route_table_ids" {
  type = "list"
}

variable "internetless" {}

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

variable "iam_ops_manager_role_name" {
  type = "string"
}

variable "create_isoseg_resources" {
  default = 0
}

variable "tags" {
  type = "map"
}
variable "use_route53" {
  default = true
  description = "Indicate whether or not to enabled route53"
}
locals {
  pas_cidr      = "${cidrsubnet(var.vpc_cidr, 6, 1)}"
  services_cidr = "${cidrsubnet(var.vpc_cidr, 6, 2)}"
}
